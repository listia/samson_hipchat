#!/bin/bash

rake TEST=plugins/hipchat/test/models/hipchat_notification_renderer_test.rb
rake TEST=plugins/hipchat/test/models/hipchat_notification_test.rb
rake TEST=plugins/hipchat/test/models/hooks_test
