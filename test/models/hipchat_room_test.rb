require_relative '../test_helper'

describe HipchatRoom do
  let(:stage) { stages(:test_production) }

  describe 'always_notify?' do
    it 'returns true when we set notify_on to always' do
      room = HipchatRoom.create!(name: 'foo', token: '123', room_id: 0, stage: stage, notify_on: "always")
      room.always_notify?.must_equal true
    end
  end

  describe 'only_notify_suceeded?' do
    it 'returns true when we set notify_on to suceeded' do
      room = HipchatRoom.create!(name: 'foo', token: '123', room_id: 0, stage: stage, notify_on: "succeeded")
      room.only_notify_suceeded?.must_equal true
    end
  end

  describe 'accept_notify?' do
    describe 'when notifiy_on = always' do
      it 'always returns true' do
        room = HipchatRoom.create!(name: 'foo', token: '123', room_id: 0, stage: stage, notify_on: "always")
        deploy = stub(job: stub(failed?: false, errored?: false, succeeded?: true))
        room.accept_notify?(deploy).must_equal true

        deploy = stub(job: stub(failed?: true, errored?: false, succeeded?: false))
        room.accept_notify?(deploy).must_equal true

        deploy = stub(job: stub(failed?: false, errored?: true, succeeded?: false))
        room.accept_notify?(deploy).must_equal true
      end
    end

    describe 'when notify_on = suceeded' do
      it 'returns true when deploy is finished, suceeded' do
        room = HipchatRoom.create!(name: 'foo', token: '123', room_id: 0, stage: stage, notify_on: "succeeded")
        deploy = stub(job: stub(failed?: false, errored?: false, succeeded?: true))
        room.accept_notify?(deploy).must_equal true
      end

      it 'returns false when deploy is not finis yet, or the result is not succeed' do
        room = HipchatRoom.create!(name: 'foo', token: '123', room_id: 0, stage: stage, notify_on: "succeeded")
        deploy = stub(job: stub(failed?: true, errored?: false, succeeded?: false))
        room.accept_notify?(deploy).must_equal false
      end
    end
  end
end
