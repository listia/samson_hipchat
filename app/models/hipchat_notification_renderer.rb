class HipchatNotificationRenderer
  def self.render(deploy, subject, opt = {})
    controller = ActionController::Base.new
    view = ActionView::Base.new(File.expand_path("../../views/samson_hipchat", __FILE__), {}, controller)
    locals = { deploy: deploy, changeset: deploy.changeset, subject: subject, option: opt }
    view.render(template: 'notification', locals: locals).chomp
  end
end
