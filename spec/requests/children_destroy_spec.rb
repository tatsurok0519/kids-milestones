require "rails_helper"

RSpec.describe "Children#destroy", type: :request do
  let(:user) { create(:user) }

  before do
    sign_in user
  end

  it "子ども削除で Achievement が消える && purge ジョブがenqueueされる" do
    child = create(:child, user: user)
    child.photo.attach(
      io: File.open(Rails.root.join("spec/fixtures/files/test.jpg")),
      filename: "test.jpg",
      content_type: "image/jpeg"
    )
    milestone = create(:milestone)
    create(:achievement, child: child, milestone: milestone)

    expect {
      delete child_path(child)
    }.to change { Achievement.count }.by(-1)
     .and change { ActiveStorage::Attachment.count }.by(-1)

    # purge_later がキューに入るか
    expect(enqueued_jobs.map { |j| j[:job] }.map(&:to_s))
      .to include("ActiveStorage::PurgeJob").or include("ActiveStorage::PurgeJob::PerformLater")
  end
end