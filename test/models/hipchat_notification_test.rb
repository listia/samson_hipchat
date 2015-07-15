require_relative '../test_helper'

describe HipchatNotification do
  let(:project) { projects(:test) }
  let(:user) { users(:deployer) }
  let(:stage) { stub(name: "staging",
                     hipchat_rooms: [
                       stub(
                         name: "x123yx",
                         token: "token123",
                         multi_message?: true,
                         accept_notify?: true)
  ],
  project: project) }

  let(:hipchat_message) { stub(content: "hello world!", style: {color: :red}, subject: "subject") }
  let(:previous_deploy) { stub(summary: "hello world!", user: user, stage: stage) }
  let(:deploy) { stub(summary: "hello world!", user: user, stage: stage, changeset: "changeset") }
  let(:notification) { HipchatNotification.new(deploy) }
  let(:endpoint) { "https://api.hipchat.com/v2/room/x123yx/notification?auth_token=token123" }

  let(:stage_multi_room) { stages(:test_production) }
  let(:deploy_in_multi_room) { stub(summary: "hello world!", user: user, stage: stage_multi_room, changeset: "changeset") }

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

  describe "multiple hipchat rooms" do
    before do
      @hipchat_room1 = HipchatRoom.create!(name: "foo", token: "token1", stage: stage_multi_room, notify_on: 0, room_id: 0)
      @hipchat_room2 = HipchatRoom.create!(name: "bar", token: "token2", stage: stage_multi_room, notify_on: 1, room_id: 0)
      @endpoint_foo = "https://api.hipchat.com/v2/room/foo/notification?auth_token=token1"
      @endpoint_bar = "https://api.hipchat.com/v2/room/bar/notification?auth_token=token2"
    end

    it "sends notifications to all rooms when succesfully" do
      job = Job.create!(command: "test", user: user, project: project) 
      deploy_in_multi_room.stubs(:job).returns(job)

      stub_request(:post, @endpoint_foo)
      stub_request(:post, @endpoint_bar)

      HipchatNotificationRenderer.stubs(:render).returns("bar")
      notification = HipchatNotification.new(deploy_in_multi_room)
      notification.deliver

      job.status = 'succeeded'

      notification.deliver

      assert_requested :post, @endpoint_foo, :times => 2
      assert_requested :post, @endpoint_bar, :times => 1
    end

    it "sends notifications to notify_on=always rooms when failed" do
      job = Job.create!(command: "test", user: user, project: project) 
      deploy_in_multi_room.stubs(:job).returns(job)

      stub_request(:post, @endpoint_foo)
      stub_request(:post, @endpoint_bar)

      HipchatNotificationRenderer.stubs(:render).returns("bar")
      notification = HipchatNotification.new(deploy_in_multi_room)
      notification.deliver
      job.status = 'failed'
      notification.deliver

      assert_requested :post, @endpoint_foo, :times => 2
      assert_requested :post, @endpoint_bar, :times => 0
    end

    it "sends only one notification when starting" do
      job = Job.create!(command: "test", user: user, project: project) 
      job.status = 'starting'
      deploy_in_multi_room.stubs(:job).returns(job)

      stub_request(:post, @endpoint_foo)
      stub_request(:post, @endpoint_bar)

      HipchatNotificationRenderer.stubs(:render).returns("bar")
      notification = HipchatNotification.new(deploy_in_multi_room)
      notification.deliver

      assert_requested :post, @endpoint_foo, :times => 1
      assert_requested :post, @endpoint_bar, :times => 0
    end

    it "attempts to delivery message to all room" do
      job = Job.create!(command: "test", user: user, project: project)
      deploy_in_multi_room.stubs(:job).returns(job)

      stub_request(:post, @endpoint_foo)
      stub_request(:post, @endpoint_bar)
      HipchatNotificationRenderer.stubs(:render).returns("bar")

      notification = HipchatNotification.new(deploy_in_multi_room)

      notification.expects(:try_delivery).with(deploy_in_multi_room, @hipchat_room1)
      notification.expects(:try_delivery).with(deploy_in_multi_room, @hipchat_room2)
      notification.deliver
    end

  end

  describe "try_delivery" do
    it "sends message if room accepts notification" do

    end

    it "will not send message if room does not accept notification" do

    end
  end

  describe "message" do
    describe "multi mode" do

      it "turns on notify" do
        m = HipchatNotification::Message.new deploy, true
        m.style[:notify].must_equal true
      end
    end

    describe "single mode" do

      it "turns off notify" do
        m = HipchatNotification::Message.new deploy, false
        m.style[:notify].must_equal false
      end
    end
  end
end
