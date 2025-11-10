import { application } from "controllers/application"
import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading"
import RewardOnceController from "./reward_once_controller"
application.register("reward-once", RewardOnceController)

// controllers フォルダ配下を自動ロード
eagerLoadControllersFrom("controllers", application)