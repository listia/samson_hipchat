Stage.class_eval do

  cattr_reader(:hipchat_rooms_cache_key) { 'hipchat-rooms-list' }

  has_many :hipchat_rooms
  accepts_nested_attributes_for :hipchat_rooms, allow_destroy: true, reject_if: :no_room_name?
  validate :room_exists?
  before_save :update_room_id

  def send_hipchat_notifications?
    hipchat_rooms.any?
  end

  def room_name
    hipchat_rooms.first.try(:name)
  end

  def no_room_name?(hipchat_attrs)
    hipchat_attrs['name'].blank?
  end

  def update_room_id
    if room_for(room_name)
      # we attempt to save room id
      self.hipchat_rooms.first.room_id = room_for(room_name)['id']
    else
      # if we fail, this maybe a notification token, just set it to 0
      self.hipchat_rooms.first.room_id = 0 if room_name
    end
  end

  def room_exists?
    if room_name
      #errors.add(:hipchat_rooms_name, "was not found. Create the room first. If this is a notification token, you can ignore this message") unless room_for(room_name)
    end
  end

  def hipchat
    client = HipChat::Client.new(hipchat_rooms.first.try(:token), :api_version => 'v2')
    client
  end

  def room_for(name)
    return nil unless name

    Rails.cache.fetch(hipchat_rooms_cache_key + name, expires_in: 15.minutes) do
      begin
        hipchat[name].get_room
      rescue HipChat::UnknownRoom, HipChat::UnknownResponseCode
        nil
      end
    end
  end
end
