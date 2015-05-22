class HipchatNotification

  def initialize(deploy)
    @deploy = deploy
    @stage = deploy.stage
  end

  def deliver
    message = Message.new(@deploy)
    begin
      hipchat[@stage.hipchat_rooms.first.name].send message.from, message.to_s, **message.style
    rescue HipChat::UnknownRoom => e
      Rails.logger.error("Room did not existed")
    rescue HipChat::Unauthorized => e
      Rails.logger.error("Invalid token to post to room")
    rescue HipChat::UnknownResponseCode => e
      Rails.logger.error("Could not deliver hipchat message: #{e.message}")
    end
  end

  class Message
    delegate :project, :stage, :user, to: :@deploy
    delegate :project_deploy_url, to: 'AppRoutes.url_helpers'

    def initialize(deploy)
      @deploy = deploy
      @stage = deploy.stage
      @project = @stage.project
      @user = @deploy.user
      @changeset = @deploy.changeset
    end

    def style
      {:color => color}
    end

    def from
      "Deploy"
    end

    def subject
      subject = "#{@user.name} is about to <a href='#{deploy_url}'>deploy</a> <strong>#{@project.name}</strong> on <strong>#{@stage.name}</strong><br>"

      subject = "#{@user.name} successfully deploy <strong>#{@project.name}</strong> @<a href='#{diff_url}'>#{@deploy.commit}...#{@changeset.try(:previous_commit)}</a> on <strong>#{@stage.name}</strong><br>" if @deploy.job.succeeded?

      subject = "#{@user.name} failed to <a href='#{deploy_url}'>deploy</a> <strong>#{@project.name}</strong> on <strong>#{@stage.name}</strong><br>" if @deploy.job.failed? || @deploy.job.errored?

      subject
    end

    def to_s
      content
    end

    def content
      return subject if @deploy.job.succeeded? || @deploy.job.failed? || @deploy.job.errored?
      @content ||= HipchatNotificationRenderer.render(@deploy, subject)
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

  def hipchat
    HipChat::Client.new @stage.hipchat_rooms.first.token, api_version: 'v2'
  end
end
