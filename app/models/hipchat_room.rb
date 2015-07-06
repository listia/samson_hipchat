class HipchatRoom < ActiveRecord::Base
  belongs_to :stage
  enum notify_on: { always: 0, succeeded: 1, failed: 2 }

  def always_notify?
    return notify_on == "always"
  end

  def only_notify_suceeded?
    return notify_on == "succeeded"
  end

  def accept_notify?(deploy)
    if deploy.job.failed? || deploy.job.errored?
      return always_notify?
    end

    if deploy.job.succeeded?
      return always_notify? || only_notify_suceeded?
    end

    # Other status, we will only notifiy if we enable always notify
    return always_notify?
  end

  # Check if we can send multi message to this room
  # Our logic: notify_on = suceeded only has to be single message becase we
  # will only notify on succeeded
  def multi_message?
    return notify_on == "always"
  end
end
