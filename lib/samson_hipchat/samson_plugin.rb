module SamsonHipchat
  class Engine < Rails::Engine
  end
end
Samson::Hooks.view :stage_form, "samson_hipchat/fields"

Samson::Hooks.callback :stage_clone do |old_stage, new_stage|
  new_stage.hipchat_rooms.build(old_stage.hipchat_rooms.map(&:attributes))
end

Samson::Hooks.callback :stage_permitted_params do
  { hipchat_rooms_attributes: [:id, :name, :token, :notify_on, :_destroy] }
end

notify = -> (deploy, _buddy) do
  if deploy.stage.send_hipchat_notifications?
    HipchatNotification.new(deploy).deliver
  end
end

Samson::Hooks.callback :before_deploy, &notify
Samson::Hooks.callback :after_deploy, &notify
