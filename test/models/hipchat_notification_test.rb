require_relative '../test_helper'

describe HipchatNotification do
  let(:project) { stub(name: "Glitter") }
  let(:user) { stub(name: "John Wu", email: "wu@rocks.com") }
  let(:stage) { stub(name: "staging", hipchat_rooms: [stub(name: "x123yx", token: "token123")], project: project) }
  let(:hipchat_message) { stub(content: "hello world!", style: {color: :red}, subject: "subject") }
  let(:previous_deploy) { stub(summary: "hello world!", user: user, stage: stage) }
  let(:deploy) { stub(summary: "hello world!", user: user, stage: stage, changeset: "changeset") }
  let(:notification) { HipchatNotification.new(deploy) }
  let(:endpoint) { "https://api.hipchat.com/v2/room/x123yx/notification?auth_token=token123" }

  before do
    HipchatNotificationRenderer.stubs(:render).returns("foo")
    HipchatNotification::Message.any_instance.stubs(:content).returns("message to send")
    HipchatNotification::Message.any_instance.stubs(:from).returns("Deployer")
    HipchatNotification::Message.any_instance.stubs(:style).returns({color: :red})
  end

  it "notifies hipchat channels configured for the stage" do
    delivery = stub_request(:post, endpoint)
    notification.deliver

    assert_requested delivery
  end

  it "renders a nicely formatted notification" do
    stub_request(:post, endpoint)
    HipchatNotificationRenderer.stubs(:render).returns("bar")
    notification.deliver

    content, format, from, color = nil
    assert_requested :post, endpoint do |request|
      body = JSON.parse(request.body)
      puts body["message"]
      content = body.fetch("message")
      format  = body.fetch("message_format")
      from  = body.fetch("from")
      color  = body.fetch("color")
      content.must_equal "message to send"
      format.must_equal "html"
      from.must_equal "Deployer"
      color.must_equal "red"
    end
  end

end
