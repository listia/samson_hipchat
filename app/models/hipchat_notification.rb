class HipchatNotification

  def initialize(deploy)
    @deploy = deploy
    @stage = deploy.stage
  end

  def deliver
    return if @stage.hipchat_rooms.empty?

    @stage.hipchat_rooms.each do |room|
      try_delivery(@deploy, room)
    end

  end

  def try_delivery(deploy, room)
    if !room.accept_notify?(deploy)
      Rails.logger.debug("No need to notify #{room.name}")
      return
    end

    Rails.logger.debug("Begin to notify #{room.name}")
    message = Message.new(deploy, room.multi_message?)
    begin
      hipchat(room.token)[room.name].send message.from, message.to_s, **message.style
    rescue HipChat::UnknownRoom => e
      Rails.logger.error("Room did not existed")
    rescue HipChat::Unauthorized => e
      Rails.logger.error("Invalid token to post to room")
    rescue HipChat::UnknownResponseCode => e
      Rails.logger.error("Could not deliver hipchat message: #{e.message} to room #{room.name}")
    end
  end

  class Message
    delegate :project, :stage, :user, to: :@deploy
    delegate :project_deploy_url, to: 'AppRoutes.url_helpers'

    def initialize(deploy, is_multi_message)
      @deploy = deploy
      @stage = deploy.stage
      @project = @stage.project
      @user = @deploy.user
      @changeset = @deploy.changeset
      @is_multi_message = is_multi_message
    end

    def style
      {:color => color, :notify => @is_multi_message}
    end

    def from
      "Deploy"
    end

    def subject
      if @is_multi_message
        subject = "#{@user.name} is <a href='#{deploy_url}'>deploying</a> <strong>#{@project.name}</strong> to <strong>#{@stage.name}</strong><br>"

        subject = "#{@user.name} successfully deployed <strong>#{@project.name}</strong> @<a href='#{diff_url}'>#{@deploy.commit}</a> to <strong>#{@stage.name}</strong><br>" if @deploy.job.succeeded?

        subject = "#{@user.name} failed to <a href='#{deploy_url}'>deployed</a> <strong>#{@project.name}</strong> to <strong>#{@stage.name}</strong><br>" if @deploy.job.failed? || @deploy.job.errored?

        subject = "#{@user.name} cancelled <a href='#{deploy_url}'>deploy</a> <strong>#{@project.name}</strong> to <strong>#{@stage.name}</strong><br>" if @deploy.job.cancelled?

        subject
      else
        subject = "#{@user.name} successfully deployed <strong>#{@project.name}</strong> @ <a href='#{diff_url}'>#{@deploy.commit}</a> to <strong>#{@stage.name}</strong><br>" if @deploy.job.succeeded?
      end
    end

    def to_s
      content
    end

    def content
      if @is_multi_message
        return subject if @deploy.job.succeeded? || @deploy.job.failed? || @deploy.job.errored?
        @content ||= HipchatNotificationRenderer.render(@deploy, subject, {is_multi_message: true})
      else
        @content ||= HipchatNotificationRenderer.render(@deploy, subject)
      end
    end

    private

    def color
      return 'green' if @deploy.job.succeeded?
      return 'red' if @deploy.job.failed? || @deploy.job.errored?
      'yellow'
    end

    def diff_url
      @changeset.github_url
    end

    def deploy_url
      project_deploy_url(@deploy.project, @deploy)
    end
  end

  private

  def hipchat(token = nil)
    HipChat::Client.new @stage.hipchat_rooms.first.token, api_version: 'v2' if token.nil?
    HipChat::Client.new token, api_version: 'v2'
  end
end
