import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"

// controllers フォルダ配下を自動ロード
eagerLoadControllersFrom("controllers", application)