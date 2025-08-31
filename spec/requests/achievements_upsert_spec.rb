require "rails_helper"

RSpec.describe "Achievements#upsert", type: :request do
  let(:user)     { create(:user) }
  let(:child)    { create(:child, user: user) }
  let(:milestone){ create(:milestone) }
  let(:path)     { "/achievements/upsert" } # ルートヘルパがあるなら置換: achievements_upsert_path 等

  def turbo_headers
    { "ACCEPT" => "text/vnd.turbo-stream.html" }
  end

  def post_upsert(state:, child_id: child.id, milestone_id: milestone.id, headers: nil)
    post path, params: { child_id:, milestone_id:, state: state }, headers: headers
  end

  context "ログイン済み" do
    before { sign_in user }

    it "state=working: 初回は作成し、working=true/achieved=false/achieved_at=nil になる" do
      expect {
        post_upsert(state: "working")
      }.to change(Achievement, :count).by(1)

      a = Achievement.find_by!(child: child, milestone: milestone)
      expect(a.working).to be(true)
      expect(a.achieved).to be(false)
      expect(a.achieved_at).to be_nil
      # 実装により 200 or 303 or 302 のことがある
      expect(response).to have_http_status(:ok)
        .or have_http_status(:see_other)
        .or have_http_status(:found)
    end

    it "state=achieved: achieved=true にし、achieved_at は初回だけ打刻（冪等）" do
      # 事前に working
      post_upsert(state: "working")

      freeze_time do
        now = Time.current
        post_upsert(state: "achieved")
        a = Achievement.find_by!(child: child, milestone: milestone)
        expect(a.working).to be(false)
        expect(a.achieved).to be(true)
        expect(a.achieved_at).to be_within(1.second).of(now)
      end

      # 2回目の achieved は achieved_at を更新しない（冪等）
      a1  = Achievement.find_by!(child: child, milestone: milestone)
      old = a1.achieved_at
      travel 5.minutes
      post_upsert(state: "achieved")
      a1.reload
      expect(a1.achieved_at).to eq(old)
    end

    it "state=clear: 全てクリアして achieved_at=nil に戻す" do
      post_upsert(state: "achieved")
      post_upsert(state: "clear")

      a = Achievement.find_by!(child: child, milestone: milestone)
      expect(a.working).to be(false)
      expect(a.achieved).to be(false)
      expect(a.achieved_at).to be_nil
    end

    it "Turbo Stream 要求時は Turbo の Content-Type か HTML を返す（実装差を許容）" do
      post_upsert(state: "working", headers: turbo_headers)
      expect(response.media_type).to eq("text/vnd.turbo-stream.html").or eq("text/html")
    end

    it "同一 (child, milestone) へ二重送信してもレコードは1件（ユニーク制約想定）" do
      expect {
        2.times { post_upsert(state: "working") }
      }.to change(Achievement, :count).by(1)
    end

    it "他人の子には 403/リダイレクト（Pundit）で拒否し、レコードは作られない" do
      other       = create(:user)
      other_child = create(:child, user: other)

      post_upsert(state: "working", child_id: other_child.id)
      # 実装により 403 or 302/401（ログイン導線や権限ハンドラによる）
      expect(response.status).to satisfy { |s| [302, 401, 403].include?(s) }
      expect(Achievement.find_by(child: other_child, milestone: milestone)).to be_nil
    end

    it "存在しない milestone なら 404/422/400 のいずれか（実装差を許容）" do
      post_upsert(state: "working", milestone_id: 0)
      expect(response.status).to satisfy { |s| [404, 422, 400].include?(s) }
    end

    it "不正な state を渡した場合は 400/422/404 のいずれか（実装差を許容）" do
      post_upsert(state: "invalid_state")
      expect(response.status).to satisfy { |s| [400, 422, 404].include?(s) }
    end
  end

  context "未ログイン" do
    it "ログインを要求する（302/401 等）" do
      post_upsert(state: "working")
      # Devise 既定では 302 でログインページへ
      expect(response.status).to satisfy { |s| [302, 401].include?(s) }
    end
  end
end