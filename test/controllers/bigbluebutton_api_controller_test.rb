# frozen_string_literal: true

require 'test_helper'

class BigBlueButtonApiControllerTest < ActionDispatch::IntegrationTest
  include BBBErrors
  include ApiHelper

  # /

  test 'index responds with only success and version for a get request' do
    Rails.configuration.x.build_number = nil

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_url
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal '2.0', response_xml.at_xpath('/response/version').text
    assert_not response_xml.at_xpath('/response/build').present?

    assert_response :success
  end

  test 'index responds with only success and version for a post request' do
    Rails.configuration.x.build_number = nil

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_url
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal '2.0', response_xml.at_xpath('/response/version').text
    assert_not response_xml.at_xpath('/response/build').present?

    assert_response :success
  end

  test 'index includes build in response if env variable is set' do
    Rails.configuration.x.build_number = 'alpha-1'

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_url
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal '2.0', response_xml.at_xpath('/response/version').text
    assert_equal 'alpha-1', response_xml.at_xpath('/response/build').text

    assert_response :success
  end

  # getMeetingInfo

  test 'getMeetingInfo responds with the correct meeting info for a post request' do
    server = Server.create!(url: 'https://test-1.example.com/bigbluebutton/api/', secret: 'test-1')
    Meeting.create!(id: 'test-meeting-1', server: server)

    url = 'https://test-1.example.com/bigbluebutton/api/getMeetingInfo?meetingID=test-meeting-1&checksum=7901d9cf0f7e63a7e5eacabfd75fabfb223259d6c045ac5b4d86fb774c371945'

    stub_request(:get, url)
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetingID>test-meeting-1</meetingID></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_get_meeting_info_url, params: { meetingID: 'test-meeting-1' }
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').content
    assert_equal 'test-meeting-1', response_xml.at_xpath('/response/meetingID').content
  end

  test 'getMeetingInfo responds with the correct meeting info for a post request with checksum value computed using SHA1' do
    server = Server.create!(url: 'https://test-1.example.com/bigbluebutton/api/', secret: 'test-1')
    Meeting.create!(id: 'SHA1_meeting', server: server)

    url = 'https://test-1.example.com/bigbluebutton/api/getMeetingInfo?meetingID=SHA1_meeting&checksum=c8cd32fbbc006424c5784b8e9679b8ff0d21c577d361d9afdab37638b1d7a4e8'

    stub_request(:get, url)
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetingID>SHA1_meeting</meetingID></response>')
    check_params = { meetingID: 'SHA1_meeting' }
    check_params[:checksum] = Digest::SHA256.hexdigest("getMeetingInfotest-2")
    Rails.configuration.x.stub(:loadbalancer_secrets, ['test-2']) do
      post(bigbluebutton_api_get_meeting_info_url, params: URI.encode_www_form(check_params))
    end
    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').content
    assert_equal 'SHA1_meeting', response_xml.at_xpath('/response/meetingID').content
  end

  test 'getMeetingInfo responds with the correct meeting info for a post request with checksum value computed using SHA256' do
    server = Server.create!(url: 'https://test-1.example.com/bigbluebutton/api/', secret: 'test-1')
    Meeting.create!(id: 'SHA256_meeting', server: server)

    url = 'https://test-1.example.com/bigbluebutton/api/getMeetingInfo?meetingID=SHA256_meeting&checksum=cd288062f4b623e1f975150e4c47a8cc212937174acafe8b1f340d5aef1877af'

    stub_request(:get, url)
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetingID>SHA256_meeting</meetingID></response>')
    check_params = { meetingID: 'SHA256_meeting' }
    check_params[:checksum] = Digest::SHA256.hexdigest("getMeetingInfotest-1")
    Rails.configuration.x.stub(:loadbalancer_secrets, ['test-1']) do
      post(bigbluebutton_api_get_meeting_info_url, params: URI.encode_www_form(check_params))
    end
    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').content
    assert_equal 'SHA256_meeting', response_xml.at_xpath('/response/meetingID').content
  end

  test 'getMeetingInfo responds with the correct meeting info for a get request' do
    server = Server.create!(url: 'https://test-1.example.com/bigbluebutton/api/', secret: 'test-1')
    Meeting.create!(id: 'test-meeting-1', server: server)

    url = 'https://test-1.example.com/bigbluebutton/api/getMeetingInfo?meetingID=test-meeting-1&checksum=7901d9cf0f7e63a7e5eacabfd75fabfb223259d6c045ac5b4d86fb774c371945'

    stub_request(:get, url)
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetingID>test-meeting-1</meetingID></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meeting_info_url, params: { meetingID: 'test-meeting-1' }
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').content
    assert_equal 'test-meeting-1', response_xml.at_xpath('/response/meetingID').content
  end

  test 'getMeetingInfo responds with appropriate error on timeout' do
    server = Server.create!(url: 'https://test-1.example.com/bigbluebutton/api/', secret: 'test-1')
    Meeting.create!(id: 'test-meeting-1', server: server)

    url = 'https://test-1.example.com/bigbluebutton/api/getMeetingInfo?meetingID=test-meeting-1&checksum=7901d9cf0f7e63a7e5eacabfd75fabfb223259d6c045ac5b4d86fb774c371945'

    stub_request(:get, url)
      .to_timeout

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meeting_info_url, params: { meetingID: 'test-meeting-1' }
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').content
    assert_equal 'internalError', response_xml.at_xpath('/response/messageKey').content
    assert_equal 'Unable to access meeting on server.', response_xml.at_xpath('/response/message').content
  end

  test 'getMeetingInfo responds with MissingMeetingIDError if meeting ID is not passed' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meeting_info_url
    end

    response_xml = Nokogiri::XML(@response.body)

    expected_error = MissingMeetingIDError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'getMeetingInfo responds with MeetingNotFoundError if meeting is not found in database' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meeting_info_url, params: { meetingID: 'test' }
    end

    response_xml = Nokogiri::XML(@response.body)

    expected_error = MeetingNotFoundError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  # isMeetingRunning

  test 'isMeetingRunning responds with the correct meeting status for a get request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api', secret: 'test-1-secret', load: 0)
    meeting1 = Meeting.find_or_create_with_server('Demo Meeting', server1, 'mp')

    stub_request(:get, encode_bbb_uri('isMeetingRunning', server1.url, server1.secret, 'meetingID' => meeting1.id))
      .to_return(body: '<response><returncode>SUCCESS</returncode><running>true</running></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_is_meeting_running_url, params: { meetingID: meeting1.id }
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').content
    assert response_xml.at_xpath('/response/running').content
  end

  test 'isMeetingRunning responds with the correct meeting status for a post request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api', secret: 'test-1-secret', load: 0)
    meeting1 = Meeting.find_or_create_with_server('Demo Meeting', server1, 'mp')

    stub_request(:get, encode_bbb_uri('isMeetingRunning', server1.url, server1.secret, 'meetingID' => meeting1.id))
      .to_return(body: '<response><returncode>SUCCESS</returncode><running>true</running></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_is_meeting_running_url, params: { meetingID: meeting1.id }
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').content
    assert response_xml.at_xpath('/response/running').content
  end

  test 'isMeetingRunning responds with appropriate error on timeout' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api', secret: 'test-1-secret', load: 0)
    meeting1 = Meeting.find_or_create_with_server('Demo Meeting', server1, 'mp')

    stub_request(:get, encode_bbb_uri('isMeetingRunning', server1.url, server1.secret, 'meetingID' => meeting1.id))
      .to_timeout

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_is_meeting_running_url, params: { meetingID: meeting1.id }
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').content
    assert_equal 'internalError', response_xml.at_xpath('/response/messageKey').content
    assert_equal 'Unable to access meeting on server.', response_xml.at_xpath('/response/message').content
  end

  test 'isMeetingRunning responds with MissingMeetingIDError if meeting ID is not passed to isMeetingRunning' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_is_meeting_running_url
    end

    response_xml = Nokogiri::XML(@response.body)

    expected_error = MissingMeetingIDError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'isMeetingRunning responds with false if meeting is not found in database for isMeetingRunning' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_is_meeting_running_url, params: { meetingID: 'test' }
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal 'false', response_xml.at_xpath('/response/running').text
  end

  # getMeetings

  test 'getMeetings responds with the correct meetings  for a get request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api', secret: 'test-1-secret', load: 1, online: true,
                            enabled: true)
    server2 = Server.create(url: 'https://test-2.example.com/bigbluebutton/api', secret: 'test-2-secret', load: 1, online: true,
                            enabled: true)

    stub_request(:get, encode_bbb_uri('getMeetings', server1.url, server1.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-1<meeting></meetings></response>')
    stub_request(:get, encode_bbb_uri('getMeetings', server2.url, server2.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-2<meeting></meetings></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meetings_url
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert response_xml.xpath('//meeting[text()="test-meeting-1"]').present?
    assert response_xml.xpath('//meeting[text()="test-meeting-2"]').present?
  end

  test 'getMeetings responds with the correct meetings for a post request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api', secret: 'test-1-secret', load: 1, online: true,
                            enabled: true)
    server2 = Server.create(url: 'https://test-2.example.com/bigbluebutton/api', secret: 'test-2-secret', load: 1, online: true,
                            enabled: true)

    stub_request(:get, encode_bbb_uri('getMeetings', server1.url, server1.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-1<meeting></meetings></response>')
    stub_request(:get, encode_bbb_uri('getMeetings', server2.url, server2.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-2<meeting></meetings></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_get_meetings_url
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert response_xml.xpath('//meeting[text()="test-meeting-1"]').present?
    assert response_xml.xpath('//meeting[text()="test-meeting-2"]').present?
  end

  test 'getMeetings responds with appropriate error on timeout' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api', secret: 'test-1-secret', load: 1, online: true,
                            enabled: true)
    server2 = Server.create(url: 'https://test-2.example.com/bigbluebutton/api', secret: 'test-2-secret', load: 1, online: true,
                            enabled: true)
    server3 = Server.create(url: 'https://test-3.example.com/bigbluebutton/api', secret: 'test-3-secret', load: 1, online: true,
                            enabled: true)

    stub_request(:get, encode_bbb_uri('getMeetings', server1.url, server1.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-1<meeting></meetings></response>')
    stub_request(:get, encode_bbb_uri('getMeetings', server2.url, server2.secret))
      .to_timeout
    stub_request(:get, encode_bbb_uri('getMeetings', server3.url, server3.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-3<meeting></meetings></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meetings_url
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').content
    assert_equal 'internalError', response_xml.at_xpath('/response/messageKey').content
    assert_equal 'Unable to access server.', response_xml.at_xpath('/response/message').content
  end

  test 'getMeetings responds with noMeetings if there are no meetings on any server' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meetings_url
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal 'noMeetings', response_xml.at_xpath('/response/messageKey').text
    assert_equal 'no meetings were found on this server', response_xml.at_xpath('/response/message').text
    assert_equal '', response_xml.at_xpath('/response/meetings').text
  end

  test 'getMeetings only makes a request to online and enabled servers' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api', secret: 'test-1-secret', load: 1, online: true,
                            enabled: true)
    server2 = Server.create(url: 'https://test-2.example.com/bigbluebutton/api', secret: 'test-2-secret', load: 1, online: true,
                            enabled: true)
    server3 = Server.create(url: 'https://test-3.example.com/bigbluebutton/api', secret: 'test-2-secret', load: 1,
                            online: false, enabled: true)

    stub_request(:get, encode_bbb_uri('getMeetings', server1.url, server1.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-1<meeting></meetings></response>')
    stub_request(:get, encode_bbb_uri('getMeetings', server2.url, server2.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-2<meeting></meetings></response>')
    stub_request(:get, encode_bbb_uri('getMeetings', server3.url, server3.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-3<meeting></meetings></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meetings_url
    end

    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert response_xml.xpath('//meeting[text()="test-meeting-1"]').present?
    assert response_xml.xpath('//meeting[text()="test-meeting-2"]').present?
    assert_not response_xml.xpath('//meeting[text()="test-meeting-3"]').present?
  end

  test 'getMeetings only makes a request to online and servers in state cordoned/enabled' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api', secret: 'test-1-secret', load: 1, online: true,
                            state: 'cordoned')
    server2 = Server.create(url: 'https://test-2.example.com/bigbluebutton/api', secret: 'test-2-secret', load: 1, online: true,
                            state: 'enabled')
    Server.create(url: 'https://test-3.example.com/bigbluebutton/api', secret: 'test-3-secret', load: 1,
                  online: false)
    Server.create(url: 'https://test-4.example.com/bigbluebutton/api', secret: 'test-4-secret', load: 1,
                  online: true, state: 'disabled')

    stub_request(:get, encode_bbb_uri('getMeetings', server1.url, server1.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-1<meeting></meetings></response>')
    stub_request(:get, encode_bbb_uri('getMeetings', server2.url, server2.secret))
      .to_return(body: '<response><returncode>SUCCESS</returncode><meetings>' \
                       '<meeting>test-meeting-2<meeting></meetings></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_get_meetings_url
    end

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert response_xml.xpath('//meeting[text()="test-meeting-1"]').present?
    assert response_xml.xpath('//meeting[text()="test-meeting-2"]').present?
    assert_not response_xml.xpath('//meeting[text()="test-meeting-3"]').present?
  end

  # /create

  test 'create responds with MissingMeetingIDError if meeting ID is not passed to create' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url
    end

    response_xml = Nokogiri::XML(@response.body)

    expected_error = MissingMeetingIDError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'create responds with InternalError if no servers are available in create' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url, params: { meetingID: 'test-meeting-1' }
    end

    response_xml = Nokogiri::XML(@response.body)

    expected_error = InternalError.new('Could not find any available servers.')

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'create responds with specific InternalError if no servers with required tag are available in create' do
    Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                  secret: 'test-1-secret', enabled: true, load: 0)

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url, params: { meetingID: 'test-meeting-1',
                                                  'meta_server-tag' => 'test-tag!' }
    end

    response_xml = Nokogiri::XML(@response.body)

    expected_error = ServerTagUnavailableError.new('test-tag')

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'create creates the room successfully for a get request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      meetingID: 'test-meeting-1', moderatorPW: 'mp',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including(params))
      .to_return do |request|
        request_params = URI.decode_www_form(request.uri.query)
        assert_match(/\A[1-9][0-9]{8}\z/, request_params.assoc('voiceBridge').last)

        { body: meeting_create_response(params[:meetingID], params[:moderatorPW]) }
      end

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url, params: params
    end

    assert_requested bbb_create

    # Reload
    server1 = Server.find(server1.id)
    meeting = Meeting.find(params[:meetingID])

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal params[:meetingID], meeting.id
    assert_equal server1.id, meeting.server.id
    assert_equal 1, server1.load
  end

  test 'create creates the room successfully for a post request' do
    skip('scalelite does not correctly handle request params in post requests')
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      meetingID: 'test-meeting-1', moderatorPW: 'mp',
    }

    bbb_create =
      stub_request(:post, "#{server1.url}create")
      .with(query: hash_including({}))
      .to_return do |request|
        assert_nil request.uri.query

        request_params = URI.decode_www_form(request.body)
        assert_equal params[:meetingID], request_params.assoc('meetingID').last
        assert_equal params[:moderatorPW], request_params.assoc('moderatorPW').last
        assert_match(/\A[1-9][0-9]{8}\z/, request_params.assoc('voiceBridge').last)

        { body: meeting_create_response(params[:meetingID], params[:moderatorPW]) }
      end

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_create_url, params: params
    end

    assert_requested bbb_create

    # Reload
    server1 = Server.find(server1.id)
    meeting = Meeting.find(params[:meetingID])

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal params[:meetingID], meeting.id
    assert_equal server1.id, meeting.server.id
    assert_equal 1, server1.load
  end

  test 'create returns an appropriate error on timeout' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      meetingID: 'test-meeting-1', moderatorPW: 'mp',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including(params))
      .to_timeout

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url, params: params
    end

    assert_requested bbb_create

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').content
    assert_equal 'internalError', response_xml.at_xpath('/response/messageKey').content
    assert_equal 'Unable to create meeting on server.', response_xml.at_xpath('/response/message').content
  end

  test 'create increments the server load by the value of load_multiplier' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0, load_multiplier: 7.0)

    params = {
      meetingID: 'test-meeting-1', moderatorPW: 'mp',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including(params))
      .to_return(body: meeting_create_response(params[:meetingID], params[:moderatorPW]))

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url, params: params
    end

    assert_requested bbb_create

    # Reload
    server1 = Server.find(server1.id)
    assert_equal 7, server1.load
  end

  test 'create with optional tag places the meeting on untagged server if no matching tagged server available' do
    Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                  secret: 'test-1-secret', enabled: true, load: 0, tag: 'wrong-tag')
    server2 = Server.create(url: 'https://test-2.example.com/bigbluebutton/api/',
                            secret: 'test-2-secret', enabled: true, load: 1)

    params = {
      meetingID: 'test-meeting-1', moderatorPW: 'mp', 'meta_server-tag' => 'test-tag'
    }

    bbb_create =
      stub_request(:get, "#{server2.url}create")
      .with(query: hash_including({}))
      .to_return do |request|
        request_params = URI.decode_www_form(request.uri.query)
        assert_equal params[:meetingID], request_params.assoc('meetingID').last
        assert_equal params[:moderatorPW], request_params.assoc('moderatorPW').last
        assert_nil request_params.assoc('meta_server-tag')

        { body: meeting_create_response(params[:meetingID], params[:moderatorPW]) }
      end

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url, params: params
    end

    assert_requested bbb_create

    # Reload
    meeting = Meeting.find(params[:meetingID])

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal params[:meetingID], meeting.id
    assert_equal server2.id, meeting.server.id
    assert_equal 2, meeting.server.load
    assert_nil meeting.server.tag
  end

  test 'create with (required) tag places the meeting on matching tagged server' do
    Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                  secret: 'test-1-secret', enabled: true, load: 0)
    server2 = Server.create(url: 'https://test-2.example.com/bigbluebutton/api/',
                            secret: 'test-2-secret', enabled: true, load: 1, tag: 'test-tag')

    create_params = {
      meetingID: 'test-meeting-1', moderatorPW: 'mp', 'meta_server-tag' => 'test-tag!'
    }
    stub_params = {
      meetingID: 'test-meeting-1', moderatorPW: 'mp', 'meta_server-tag' => 'test-tag'
    }

    bbb_create =
      stub_request(:get, "#{server2.url}create")
      .with(query: hash_including(stub_params))
      .to_return(body: meeting_create_response(stub_params[:meetingID], stub_params[:moderatorPW]))

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url, params: create_params
    end

    assert_requested bbb_create

    # Reload
    meeting = Meeting.find(create_params[:meetingID])

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal create_params[:meetingID], meeting.id
    assert_equal server2.id, meeting.server.id
    assert_equal 2, meeting.server.load
    assert_equal 'test-tag', meeting.server.tag
  end

  test 'create sets the duration param to MAX_MEETING_DURATION if set' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      meetingID: 'test-meeting-1',
      moderatorPW: 'test-password',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including(params.merge(duration: '3600')))
      .to_return(body: meeting_create_response(params[:meetingID], params[:moderatorPW]))

    Rails.configuration.x.stub(:max_meeting_duration, 3600) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end
    end

    assert_requested bbb_create

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
  end

  test 'create sets the duration param to MAX_MEETING_DURATION if passed duration is greater than MAX_MEETING_DURATION' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      duration: 5000,
      meetingID: 'test-meeting-1',
      moderatorPW: 'test-password',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including(params.merge(duration: '3600')))
      .to_return(body: meeting_create_response(params[:meetingID], params[:moderatorPW]))

    Rails.configuration.x.stub(:max_meeting_duration, 3600) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end
    end

    assert_requested bbb_create

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
  end

  test 'create sets the duration param to MAX_MEETING_DURATION if passed duration is 0' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      duration: 0,
      meetingID: 'test-meeting-1',
      moderatorPW: 'test-password',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including(params.merge(duration: '3600')))
      .to_return(body: meeting_create_response(params[:meetingID], params[:moderatorPW]))

    Rails.configuration.x.stub(:max_meeting_duration, 3600) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end
    end

    assert_requested bbb_create

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
  end

  test 'create does not set the duration param to MAX_MEETING_DURATION if passed duration is less than MAX_MEETING_DURATION' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      duration: '1200',
      meetingID: 'test-meeting-1',
      moderatorPW: 'test-password',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including(params))
      .to_return(body: meeting_create_response(params[:meetingID], params[:moderatorPW]))

    Rails.configuration.x.stub(:max_meeting_duration, 3600) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end
    end

    assert_requested bbb_create

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
  end

  test 'create creates the room successfully  with only permitted params for create' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      meetingID: 'test-meeting-1', test4: '', test2: '', moderatorPW: 'test-password',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including({}))
      .to_return do |request|
        request_params = URI.decode_www_form(request.uri.query)
        assert_equal params[:meetingID], request_params.assoc('meetingID').last
        assert_equal params[:moderatorPW], request_params.assoc('moderatorPW').last
        assert_match(/[1-9][0-9]{8}/, request_params.assoc('voiceBridge').last)
        # Filtered params:
        assert_nil request_params.assoc('test4')
        assert_nil request_params.assoc('test2')

        { body: meeting_create_response(params[:meetingID], params[:moderatorPW]) }
      end

    mocked_method = Minitest::Mock.new
    return_value = { 'meetingID' => 'test-meeting-1' }

    Rails.configuration.x.stub(:create_exclude_params, %w[test4 test2]) do
      mocked_method.expect(:pass_through_params, return_value, [Rails.configuration.x.create_exclude_params])
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end
      mocked_method.pass_through_params(%w[test4 test2])
      mocked_method.verify
    end

    assert_requested bbb_create

    # Reload
    server1 = Server.find(server1.id)
    meeting = Meeting.find(params[:meetingID])

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal params[:meetingID], meeting.id
    assert_equal server1.id, meeting.server.id
    assert_equal 1, server1.load
  end

  test 'create creates the room successfully with given params if excluded params list is empty' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      meetingID: 'test-meeting-1', test4: '', test2: '', moderatorPW: 'test-password',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including(params))
      .to_return(body: meeting_create_response(params[:meetingID], params[:moderatorPW]))

    mocked_method = Minitest::Mock.new
    return_value = { meetingID: 'test-meeting-1', test4: '', test2: '' }

    Rails.configuration.x.stub(:create_exclude_params, []) do
      mocked_method.expect(:pass_through_params, return_value, [Rails.configuration.x.create_exclude_params])
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end
      mocked_method.pass_through_params([])
      mocked_method.verify
    end

    assert_requested bbb_create

    # Reload
    server1 = Server.find(server1.id)
    meeting = Meeting.find(params[:meetingID])

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal params[:meetingID], meeting.id
    assert_equal server1.id, meeting.server.id
    assert_equal 1, server1.load
  end

  test 'create creates a record in callback_data if  params["meta_bn-recording-ready-url"] is present in request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)
    params = {
      meetingID: 'test-meeting-1', test4: '', test2: '', moderatorPW: 'test-password',
      'meta_bn-recording-ready-url' => 'https://test-2.example.com/recording-ready/',
    }

    bbb_create =
      stub_request(:get, "#{server1.url}create")
      .with(query: hash_including({}))
      .to_return do |request|
        request_params = URI.decode_www_form(request.uri.query)
        assert_equal params[:meetingID], request_params.assoc('meetingID').last
        assert_equal params[:test4], request_params.assoc('test4').last
        assert_equal params[:test2], request_params.assoc('test2').last
        assert_equal params[:moderatorPW], request_params.assoc('moderatorPW').last
        assert_nil request_params.assoc('meta_bn-recording-ready-url')

        { body: meeting_create_response(params[:meetingID], params[:moderatorPW]) }
      end

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_create_url, params: params
    end

    assert_requested bbb_create

    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text

    callback_data = CallbackData.find_by(meeting_id: params[:meetingID])
    assert_equal({ recording_ready_url: params['meta_bn-recording-ready-url'] }, callback_data.callback_attributes)
  end

  test 'create creates a record in callback_data if  params["meta_analytics-callback-url"] is present in request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)
    params = {
      meetingID: 'test-meeting-66', test4: '', test2: '', moderatorPW: 'test-password',
      'meta_analytics-callback-url' => 'https://example.com/analytics_callback',
    }

    Rails.configuration.x.stub(:url_host, 'test.scalelite.com') do
      bbb_create =
        stub_request(:get, "#{server1.url}create")
        .with(query: hash_including(
          params.merge(
            'meta_analytics-callback-url' =>
              "https://#{Rails.configuration.x.url_host}#{bigbluebutton_api_analytics_callback_path}"
          )
        ))
        .to_return(body: meeting_create_response(params[:meetingID], params[:moderatorPW]))

      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end

      assert_requested bbb_create
    end
    response_xml = Nokogiri::XML(@response.body)
    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text

    callback_data = CallbackData.find_by(meeting_id: params[:meetingID])
    assert_equal({ analytics_callback_url: params['meta_analytics-callback-url'] }, callback_data.callback_attributes)
  end

  test 'create sets default params if they are not already set' do
    server = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/', secret: 'test-1-secret', enabled: true, load: 0)
    params = {
      meetingID: 'test-meeting-1',
      param1: 'param1',
    }
    default_params = {
      param1: 'not-param1',
      param2: 'param2',
    }

    bbb_create =
      stub_request(:get, "#{server.url}create")
      .with(query: hash_including(default_params.merge(params)))
      .to_return(body: meeting_create_response(params[:meetingID]))

    Rails.configuration.x.stub(:default_create_params, default_params) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end
    end

    assert_requested bbb_create
  end

  test 'create sets override params even if they are set' do
    server = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/', secret: 'test-1-secret', enabled: true, load: 0)
    params = {
      meetingID: 'test-meeting-1',
      param1: 'not-param1',
    }
    override_params = {
      param1: 'param1',
      param2: 'param2',
    }

    bbb_create =
      stub_request(:get, "#{server.url}create")
      .with(query: hash_including(params.merge(override_params)))
      .to_return(body: meeting_create_response(params[:meetingID]))

    Rails.configuration.x.stub(:override_create_params, override_params) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_create_url, params: params
      end
    end

    assert_requested bbb_create
  end

  # analytics_callback

  test 'analytics_callback makes a callback to the specific meetings analytics_callback_url stored in
        callback_attributes table' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)
    params = {
      meetingID: 'test-meeting-1111', test4: '', test2: '', moderatorPW: 'test-password',
      'meta_analytics-callback-url' => 'https://callback.example.com/analytics_callback',
    }

    stub_request(:get, "#{server1.url}create")
      .with(query: hash_including({}))
      .to_return(body: meeting_create_response(params[:meetingID], params[:moderatorPW]))

    callback = stub_request(:post, params['meta_analytics-callback-url'])
               .to_return(status: :ok, body: '', headers: {})

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      BigBlueButtonApiController.stub_any_instance(:valid_token?, true) do
        Rails.configuration.x.stub(:url_host, 'test.scalelite.com') do
          get bigbluebutton_api_create_url, params: params
          post(
            bigbluebutton_api_analytics_callback_url,
            params: { meeting_id: 'test-meeting-1111' },
            headers: { 'HTTP_AUTHORIZATION' => 'Bearer ABCD' }
          )
        end
      end
    end
    assert_equal 204, @response.status
    assert_requested(callback)
    callback_data = CallbackData.find_by(meeting_id: params[:meetingID])
    assert_equal({ analytics_callback_url: params['meta_analytics-callback-url'] }, callback_data.callback_attributes)
  end

  # end

  test 'end responds with MissingMeetingIDError if meeting ID is not passed to end' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_end_url
    end
    response_xml = Nokogiri::XML(@response.body)

    expected_error = MissingMeetingIDError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'end responds with MeetingNotFoundError if meeting is not found in database for end' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_end_url, params: { meetingID: 'test-meeting-1' }
    end
    response_xml = Nokogiri::XML(@response.body)

    expected_error = MeetingNotFoundError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'end responds with MeetingNotFoundError if meetingID && password are passed but meeting doesnt exist' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)

    params = {
      meetingID: 'test-meeting-1',
      password: 'test-password',
    }

    stub_request(:get, encode_bbb_uri('end', server1.url, server1.secret, params))
      .to_return(body: '<response><returncode>FAILED</returncode><messageKey>notFound</messageKey>' \
                       '<message>We could not find a meeting with that meeting ID - perhaps the meeting is not yet ' \
                       'running?</message></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_end_url, params: params
    end
    response_xml = Nokogiri::XML(@response.body)

    expected_error = MeetingNotFoundError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'end responds with sentEndMeetingRequest if meeting exists and password is correct for a get request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)
    Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')

    params = {
      meetingID: 'test-meeting-1',
      password: 'test-password',
    }

    stub_request(:get, encode_bbb_uri('end', server1.url, server1.secret, params))
      .to_return(body: '<response><returncode>SUCCESS</returncode><messageKey>sentEndMeetingRequest</messageKey>' \
                       '<message>A request to end the meeting was sent. Please wait a few seconds, and then use the getMeetingInfo ' \
                       'or isMeetingRunning API calls to verify that it was ended.</message></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_end_url, params: params
    end
    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal 'sentEndMeetingRequest', response_xml.at_xpath('/response/messageKey').text

    assert_raises(ApplicationRedisRecord::RecordNotFound) do
      Meeting.find('test-meeting-1')
    end
  end

  test 'end responds with sentEndMeetingRequest if meeting exists and password is correct for a post request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)
    Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')

    params = {
      meetingID: 'test-meeting-1',
      password: 'test-password',
    }

    stub_request(:get, encode_bbb_uri('end', server1.url, server1.secret, params))
      .to_return(body: '<response><returncode>SUCCESS</returncode><messageKey>sentEndMeetingRequest</messageKey>' \
                       '<message>A request to end the meeting was sent. Please wait a few seconds, and then use the getMeetingInfo ' \
                       'or isMeetingRunning API calls to verify that it was ended.</message></response>')

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_end_url, params: params
    end
    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'SUCCESS', response_xml.at_xpath('/response/returncode').text
    assert_equal 'sentEndMeetingRequest', response_xml.at_xpath('/response/messageKey').text

    assert_raises(ApplicationRedisRecord::RecordNotFound) do
      Meeting.find('test-meeting-1')
    end
  end

  test 'end returns error on timeout but still deletes meeting' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0)
    Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')

    params = {
      meetingID: 'test-meeting-1',
      password: 'test-password',
    }

    stub_request(:get, encode_bbb_uri('end', server1.url, server1.secret, params))
      .to_timeout

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_end_url, params: params
    end
    response_xml = Nokogiri::XML(@response.body)

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal 'internalError', response_xml.at_xpath('/response/messageKey').text
    assert_equal 'Unable to access meeting on server.', response_xml.at_xpath('/response/message').text

    assert_raises(ApplicationRedisRecord::RecordNotFound) do
      Meeting.find('test-meeting-1')
    end
  end

  # join

  test 'join responds with MissingMeetingIDError if meeting ID is not passed to join' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_join_url
    end
    response_xml = Nokogiri::XML(@response.body)

    expected_error = MissingMeetingIDError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'join responds with MeetingNotFoundError if meeting is not found in database for join' do
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_join_url, params: { meetingID: 'test-meeting-1' }
    end
    response_xml = Nokogiri::XML(@response.body)

    expected_error = MeetingNotFoundError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'join redirects user to the corrent join url for a get request' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0, online: true)
    meeting = Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')

    params = { meetingID: meeting.id, password: 'test-password', fullName: 'test-name' }

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_join_url, params: params
    end

    assert_redirected_to encode_bbb_uri('join', server1.url, server1.secret, params).to_s
  end

  test 'join does not support POST requests' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0, online: true)
    meeting = Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')

    params = { meetingID: meeting.id, password: 'test-password', fullName: 'test-name' }

    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_join_url, params: params
    end

    assert_response :success
    response_xml = Nokogiri.XML(response.body)
    expected_error = BBBErrors::UnsupportedRequestError.new
    assert_equal(response_xml.at_xpath('/response/returncode').text, 'FAILED')
    assert_equal(response_xml.at_xpath('/response/messageKey').text, expected_error.message_key)
    assert_equal(response_xml.at_xpath('/response/message').text, expected_error.message)
  end

  test 'join increments the server load by the value of load_multiplier' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, online: true, load: 0, load_multiplier: 7.0)
    meeting = Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')

    # Reload 1
    server1 = Server.find(server1.id)
    load_before_join = server1.load

    params = { meetingID: meeting.id, moderatorPW: 'mp', fullName: 'test-name' }
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_join_url, params: params
    end

    # Reload 2
    server1 = Server.find(server1.id)
    expected_load = load_before_join + 7.0
    assert_equal expected_load, server1.load
  end

  test 'join redirects user to the current join url with only permitted params for join' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0, online: true)
    meeting = Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')
    params = { meetingID: meeting.id, password: 'test-password', fullName: 'test-name', test1: '', test2: '' }
    Rails.configuration.x.stub(:join_exclude_params, %w[test1 test2]) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_join_url, params: params
      end
      filtered_params = { meetingID: meeting.id, password: 'test-password', fullName: 'test-name' }
      assert_redirected_to encode_bbb_uri('join', server1.url, server1.secret, filtered_params).to_s
    end
  end

  test 'join redirects user to the current join url with given params if excluded params list is empty' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: true, load: 0, online: true)
    meeting = Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')
    params = { meetingID: meeting.id, password: 'test-password', fullName: 'test-name', test1: '', test2: '' }
    Rails.configuration.x.stub(:join_exclude_params, []) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_join_url, params: params
      end
      assert_redirected_to encode_bbb_uri('join', server1.url, server1.secret, params).to_s
    end
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_join_url, params: params
    end
    filtered_params = { meetingID: meeting.id, password: 'test-password', fullName: 'test-name' }
    assert_equal Rails.configuration.x.join_exclude_params, %w[test1 test2]
    assert_redirected_to encode_bbb_uri('join', server1.url, server1.secret, filtered_params).to_s
  end

  test 'join responds with ServerUnavailableError if server is disabled' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', enabled: false, load: 0, online: true)
    Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_join_url, params: { meetingID: 'test-meeting-1' }
    end
    response_xml = Nokogiri::XML(@response.body)

    expected_error = ServerUnavailableError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'join responds with ServerUnavailableError if server is offline' do
    server1 = Server.create(url: 'https://test-1.example.com/bigbluebutton/api/',
                            secret: 'test-1-secret', load: 0, online: false, enabled: true)
    Meeting.find_or_create_with_server('test-meeting-1', server1, 'mp')
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      get bigbluebutton_api_join_url, params: { meetingID: 'test-meeting-1' }
    end
    response_xml = Nokogiri::XML(@response.body)

    expected_error = ServerUnavailableError.new

    assert_equal 'FAILED', response_xml.at_xpath('/response/returncode').text
    assert_equal expected_error.message_key, response_xml.at_xpath('/response/messageKey').text
    assert_equal expected_error.message, response_xml.at_xpath('/response/message').text
  end

  test 'join sets default params if they are not already set' do
    server = Server.create(
      url: 'https://test-1.example.com/bigbluebutton/api/',
      secret: 'test-1-secret',
      enabled: true,
      load: 0,
      online: true
    )
    meeting = Meeting.find_or_create_with_server('test-meeting-1', server, 'mp')
    params = {
      meetingID: meeting.id,
      moderatorPW: 'mp',
      fullName: 'test-name',
      param1: 'param1'
    }
    default_params = {
      param1: 'not-param1',
      param2: 'param2',
    }

    Rails.configuration.x.stub(:default_join_params, default_params) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_join_url, params: params
      end
    end

    assert_operator(@response.headers['Location'], :starts_with?, server.url)
    redirect_url = URI(@response.headers['Location'])
    redirect_params = URI.decode_www_form(redirect_url.query)
    assert_equal(params[:param1], redirect_params.assoc('param1').last)
    assert_equal(default_params[:param2], redirect_params.assoc('param2').last)
  end

  test 'join sets override params even if they are set' do
    server = Server.create(
      url: 'https://test-1.example.com/bigbluebutton/api/',
      secret: 'test-1-secret',
      enabled: true,
      load: 0,
      online: true
    )
    meeting = Meeting.find_or_create_with_server('test-meeting-1', server, 'mp')
    params = {
      meetingID: meeting.id,
      moderatorPW: 'mp',
      fullName: 'test-name',
      param1: 'not-param1'
    }
    override_params = {
      param1: 'param1',
      param2: 'param2',
    }

    Rails.configuration.x.stub(:override_join_params, override_params) do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        get bigbluebutton_api_join_url, params: params
      end
    end

    assert_operator(@response.headers['Location'], :starts_with?, server.url)
    redirect_url = URI(@response.headers['Location'])
    redirect_params = URI.decode_www_form(redirect_url.query)
    assert_equal(override_params[:param1], redirect_params.assoc('param1').last)
    assert_equal(override_params[:param2], redirect_params.assoc('param2').last)
  end

  # getRecordings

  test 'getRecordings with no parameters returns checksum error' do
    get bigbluebutton_api_get_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'getRecordings with invalid checksum returns checksum error' do
    get bigbluebutton_api_get_recordings_url, params: "checksum=#{'x' * 40}"
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'getRecordings with only checksum returns all recordings for a get request' do
    create_list(:recording, 3, state: 'published')
    params = encode_bbb_params('getRecordings', '')
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 3
  end

  test 'getRecordings with get_recordings_api_filtered does not return any recordings and returns error response
        if no meetingId/recordId is provided' do
    create_list(:recording, 3, state: 'published')
    params = encode_bbb_params('getRecordings', '')
    Rails.configuration.x.stub(:get_recordings_api_filtered, true) { get bigbluebutton_api_get_recordings_url, params: params }
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'missingParameters'
    assert_select 'response>message', 'param meetingID or recordID must be included.'
  end

  test 'getRecordings with only checksum returns all recordings for a post request' do
    create_list(:recording, 3, state: 'published')
    params = encode_bbb_params('getRecordings', '')
    post bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 3
  end

  test 'getRecordings fetches recording by meeting id' do
    r = create(:recording, :published, participants: 3, state: 'published')
    podcast = create(:playback_format, recording: r, format: 'podcast')
    presentation = create(:playback_format, recording: r, format: 'presentation')

    params = encode_bbb_params('getRecordings', { meetingID: r.meeting_id }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    url_prefix = "#{@request.protocol}#{@request.host}"
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 1
    assert_select 'response>recordings>recording' do |rec_el|
      assert_select rec_el, 'recordID', r.record_id
      assert_select rec_el, 'meetingID', r.meeting_id
      assert_select rec_el, 'internalMeetingID', r.record_id
      assert_select rec_el, 'name', r.name
      assert_select rec_el, 'published', 'true'
      assert_select rec_el, 'state', 'published'
      assert_select rec_el, 'startTime', (r.starttime.to_r * 1000).to_i.to_s
      assert_select rec_el, 'endTime', (r.endtime.to_r * 1000).to_i.to_s
      assert_select rec_el, 'participants', '3'

      assert_select rec_el, 'playback>format', r.playback_formats.count
      assert_select rec_el, 'playback>format' do |format_els|
        format_els.each do |format_el|
          format_type = css_select(format_el, 'type')
          pf = nil
          case format_type.first.content
          when 'podcast' then pf = podcast
          when 'presentation' then pf = presentation
          else flunk("Unexpected playback format: #{format_type.first.content}")
          end

          assert_select format_el, 'type', pf.format
          assert_select format_el, 'url', "#{url_prefix}#{pf.url}"
          assert_select format_el, 'length', pf.length.to_s
          assert_select format_el, 'processingTime', pf.processing_time.to_s

          imgs = css_select(format_el, 'preview>images>image')
          assert_equal imgs.length, pf.thumbnails.count
          imgs.each_with_index do |img, i|
            t = thumbnails("fred_room_#{pf.format}_thumb#{i + 1}")
            assert_equal img['alt'], t.alt
            assert_equal img['height'], t.height.to_s
            assert_equal img['width'], t.width.to_s
            assert_equal img.content, "#{url_prefix}#{t.url}"
          end
        end
      end
    end
  end

  test 'getRecordings with get_recordings_api_filtered fetches recording by meeting id' do
    r = create(:recording, :published, participants: 3, state: 'published')
    podcast = create(:playback_format, recording: r, format: 'podcast')
    presentation = create(:playback_format, recording: r, format: 'presentation')

    params = encode_bbb_params('getRecordings', { meetingID: r.meeting_id }.to_query)
    Rails.configuration.x.stub(:get_recordings_api_filtered, true) { get bigbluebutton_api_get_recordings_url, params: params }
    url_prefix = "#{@request.protocol}#{@request.host}"
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 1
    assert_select 'response>recordings>recording' do |rec_el|
      assert_select rec_el, 'recordID', r.record_id
      assert_select rec_el, 'meetingID', r.meeting_id
      assert_select rec_el, 'internalMeetingID', r.record_id
      assert_select rec_el, 'name', r.name
      assert_select rec_el, 'published', 'true'
      assert_select rec_el, 'state', 'published'
      assert_select rec_el, 'startTime', (r.starttime.to_r * 1000).to_i.to_s
      assert_select rec_el, 'endTime', (r.endtime.to_r * 1000).to_i.to_s
      assert_select rec_el, 'participants', '3'

      assert_select rec_el, 'playback>format', r.playback_formats.count
      assert_select rec_el, 'playback>format' do |format_els|
        format_els.each do |format_el|
          format_type = css_select(format_el, 'type')
          pf = nil
          case format_type.first.content
          when 'podcast' then pf = podcast
          when 'presentation' then pf = presentation
          else flunk("Unexpected playback format: #{format_type.first.content}")
          end

          assert_select format_el, 'type', pf.format
          assert_select format_el, 'url', "#{url_prefix}#{pf.url}"
          assert_select format_el, 'length', pf.length.to_s
          assert_select format_el, 'processingTime', pf.processing_time.to_s

          imgs = css_select(format_el, 'preview>images>image')
          assert_equal imgs.length, pf.thumbnails.count
          imgs.each_with_index do |img, i|
            t = thumbnails("fred_room_#{pf.format}_thumb#{i + 1}")
            assert_equal img['alt'], t.alt
            assert_equal img['height'], t.height.to_s
            assert_equal img['width'], t.width.to_s
            assert_equal img.content, "#{url_prefix}#{t.url}"
          end
        end
      end
    end
  end

  test 'getRecordings allows multiple comma-separated meeting IDs' do
    create_list(:recording, 5, state: 'published')
    r1 = create(:recording, state: 'published')
    r2 = create(:recording, state: 'published')

    params = encode_bbb_params('getRecordings', {
      meetingID: [r1.meeting_id, r2.meeting_id].join(','),
    }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 2
  end

  test 'getRecordings with get_recordings_api_filtered allows multiple comma-separated meeting IDs' do
    create_list(:recording, 5, state: 'published')
    r1 = create(:recording, state: 'published')
    r2 = create(:recording, state: 'published')

    params = encode_bbb_params('getRecordings', {
      meetingID: [r1.meeting_id, r2.meeting_id].join(','),
    }.to_query)
    Rails.configuration.x.stub(:get_recordings_api_filtered, true) { get bigbluebutton_api_get_recordings_url, params: params }
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 2
  end

  test 'getRecordings does case-sensitive match on recording id' do
    r = create(:recording, state: 'published')
    params = encode_bbb_params('getRecordings', { recordID: r.record_id.upcase }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>messageKey', 'noRecordings'
    assert_select 'response>recordings>recording', 0
  end

  test 'getRecordings does prefix match on recording id' do
    create_list(:recording, 5, state: 'published')
    r = create(:recording, meeting_id: 'bulk-prefix-match', state: 'published')
    create_list(:recording, 19, meeting_id: 'bulk-prefix-match', state: 'published') # rubocop:disable FactoryBot/ExcessiveCreateList
    params = encode_bbb_params('getRecordings', { recordID: r.record_id[0, 40] }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 20
    assert_select 'recording>meetingID', r.meeting_id
  end

  test 'getRecordings allows multiple comma-separated recording IDs' do
    create_list(:recording, 5, state: 'published')
    r1 = create(:recording, state: 'published')
    r2 = create(:recording, state: 'published')

    params = encode_bbb_params('getRecordings', {
      recordID: [r1.record_id, r2.record_id].join(','),
    }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 2
  end

  test 'getRecordings with get_recordings_api_filtered allows multiple comma-separated recording IDs' do
    create_list(:recording, 5, state: 'published')
    r1 = create(:recording, state: 'published')
    r2 = create(:recording, state: 'published')

    params = encode_bbb_params('getRecordings', {
      recordID: [r1.record_id, r2.record_id].join(','),
    }.to_query)
    Rails.configuration.x.stub(:get_recordings_api_filtered, true) { get bigbluebutton_api_get_recordings_url, params: params }

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 2
  end

  test 'getRecordings filter based on recording states' do
    create_list(:recording, 5)
    r1 = create(:recording, state: 'processing')
    r2 = create(:recording, state: 'unpublished')
    r3 = create(:recording, state: 'deleted')

    params = encode_bbb_params('getRecordings', {
      recordID: [r1.record_id, r2.record_id, r3.record_id].join(','),
      state: %w[published unpublished].join(','),
    }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 1
  end

  test 'getRecordings with get_recordings_api_filtered filters based on recording states' do
    create_list(:recording, 5, state: 'deleted')
    r1 = create(:recording, state: 'published')
    r2 = create(:recording, state: 'unpublished')
    r3 = create(:recording, state: 'deleted')

    params = encode_bbb_params('getRecordings', {
      recordID: [r1.record_id, r2.record_id, r3.record_id].join(','),
      state: %w[published unpublished].join(','),
    }.to_query)
    Rails.configuration.x.stub(:get_recordings_api_filtered, true) { get bigbluebutton_api_get_recordings_url, params: params }

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 2
  end

  test 'getRecordings filter based on recording states and meta_params' do
    create_list(:recording, 5, state: 'processing')
    r1 = create(:recording, state: 'published')
    r2 = create(:recording, state: 'unpublished')
    r3 = create(:recording, state: 'deleted')
    create(:metadatum, recording: r1, key: 'bbb-context-name', value: 'test1')
    create(:metadatum, recording: r3, key: 'bbb-origin-tag', value: 'GL')
    create(:metadatum, recording: r2, key: 'bbb-origin-tag', value: 'GL')

    params = encode_bbb_params('getRecordings', {
      recordID: [r1.record_id, r2.record_id, r3.record_id].join(','),
      state: %w[published unpublished deleted].join(','),
      'meta_bbb-context-name': %w[test1 test2].join(','),
      'meta_bbb-origin-tag': ['GL'].join(','),
    }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 3
  end

  test 'getRecordings with get_recordings_api_filtered filters based on recording states and meta_params' do
    create_list(:recording, 5)
    r1 = create(:recording, state: 'published')
    r2 = create(:recording, state: 'unpublished')
    r3 = create(:recording)
    create(:metadatum, recording: r1, key: 'bbb-context-name', value: 'test1')
    create(:metadatum, recording: r3, key: 'bbb-origin-tag', value: 'GL')
    create(:metadatum, recording: r2, key: 'bbb-origin-tag', value: 'GL')

    params = encode_bbb_params('getRecordings', {
      recordID: [r1.record_id, r2.record_id, r3.record_id].join(','),
      state: %w[published unpublished].join(','),
      'meta_bbb-context-name': %w[test1 test2].join(','),
      'meta_bbb-origin-tag': ['GL'].join(','),
    }.to_query)
    Rails.configuration.x.stub(:get_recordings_api_filtered, true) { get bigbluebutton_api_get_recordings_url, params: params }

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 2
  end

  test 'getRecordings filter based on recording states and meta_params and
       returns no recordings if no match found' do
    create_list(:recording, 5)
    r1 = create(:recording, state: 'published')
    r2 = create(:recording, state: 'unpublished')
    r3 = create(:recording)
    create(:metadatum, recording: r1, key: 'bbb-context-name', value: 'test12')
    create(:metadatum, recording: r3, key: 'bbb-origin-tag', value: 'GL1')
    create(:metadatum, recording: r2, key: 'bbb-origin-tag', value: 'GL2')

    params = encode_bbb_params('getRecordings', {
      recordID: [r1.record_id, r2.record_id, r3.record_id].join(','),
      state: %w[published unpublished].join(','),
      'meta_bbb-context-name': %w[test1 test2].join(','),
      'meta_bbb-origin-tag': ['GL'].join(','),
    }.to_query)
    get bigbluebutton_api_get_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>recordings>recording', 0
  end

  # publishRecordings

  test 'publishRecordings with no parameters returns checksum error' do
    get bigbluebutton_api_publish_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'publishRecordings with invalid checksum returns checksum error' do
    get bigbluebutton_api_publish_recordings_url, params: "checksum=#{'x' * 40}"
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'publishRecordings requires recordID parameter' do
    params = encode_bbb_params('publishRecordings', { publish: 'true' }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'missingParamRecordID'
  end

  test 'publishRecordings requires publish parameter' do
    r = create(:recording)
    params = encode_bbb_params('publishRecordings', { recordID: r.record_id }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'missingParamPublish'
  end

  test 'publishRecordings updates published property to false' do
    r = create(:recording, :published)
    assert_equal r.published, true

    params = encode_bbb_params('publishRecordings', { recordID: r.record_id, publish: 'false' }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>published', 'false'

    r.reload
    assert_equal r.published, false
  end

  test 'publishRecordings updates published property to true for a get request' do
    r = create(:recording, :unpublished)
    assert_equal r.published, false

    params = encode_bbb_params('publishRecordings', { recordID: r.record_id, publish: 'true' }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>published', 'true'

    r.reload
    assert_equal r.published, true
  end

  test 'publishRecordings does not support POST requests' do
    r = create(:recording, :unpublished)
    assert_equal r.published, false

    params = encode_bbb_params('publishRecordings', { recordID: r.record_id, publish: 'true' }.to_query)
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_publish_recordings_url, params: params
    end

    response_xml = Nokogiri.XML(response.body)
    expected_error = BBBErrors::UnsupportedRequestError.new
    assert_equal('FAILED', response_xml.at_xpath('/response/returncode').text)
    assert_equal(expected_error.message_key, response_xml.at_xpath('/response/messageKey').text)
    assert_equal(expected_error.message, response_xml.at_xpath('/response/message').text)

    r.reload
    assert_equal r.published, false
  end

  test 'publishRecordings returns error if no recording found' do
    create(:recording)

    params = encode_bbb_params('publishRecordings', { recordID: 'not-a-real-record-id', publish: 'true' }.to_query)
    get bigbluebutton_api_publish_recordings_url, params: params

    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'notFound'
  end

  # updateRecordings

  test 'updateRecordings with no parameters returns checksum error' do
    get bigbluebutton_api_update_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'updateRecordings with invalid checksum returns checksum error' do
    get bigbluebutton_api_update_recordings_url, params: "checksum=#{'x' * 40}"
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'updateRecordings requires recordID parameter' do
    params = encode_bbb_params('updateRecordings', '')
    get bigbluebutton_api_update_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'missingParamRecordID'
  end

  test 'updateRecordings adds a new meta parameter' do
    r = create(:recording)

    meta_params = { 'newparam' => 'newvalue' }
    params = encode_bbb_params('updateRecordings', {
      recordID: r.record_id,
    }.merge(meta_params.transform_keys { |k| "meta_#{k}" }).to_query)

    assert_difference 'Metadatum.count', 1 do
      get bigbluebutton_api_update_recordings_url, params: params
    end

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>updated', 'true'

    meta_params.each do |k, v|
      m = r.metadata.find_by(key: k)
      assert_not m.nil?
      assert m.value, v
    end
  end

  test 'updateRecordings updates an existing meta parameter for a get request' do
    r = create(:recording_with_metadata, meta_params: { 'gl-listed' => 'true' })

    meta_params = { 'gl-listed' => 'false' }
    params = encode_bbb_params('updateRecordings', {
      recordID: r.record_id,
    }.merge(meta_params.transform_keys { |k| "meta_#{k}" }).to_query)

    assert_no_difference 'Metadatum.count' do
      get bigbluebutton_api_update_recordings_url, params: params
    end

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>updated', 'true'

    m = r.metadata.find_by(key: 'gl-listed')
    assert_equal m.value, meta_params['gl-listed']
  end

  test 'updateRecordings updates an existing meta parameter for a post request' do
    r = create(:recording_with_metadata, meta_params: { 'gl-listed' => 'true' })

    meta_params = { 'gl-listed' => 'true' }
    params = encode_bbb_params('updateRecordings', {
      recordID: r.record_id,
    }.merge(meta_params.transform_keys { |k| "meta_#{k}" }).to_query)

    assert_no_difference 'Metadatum.count' do
      BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
        post bigbluebutton_api_update_recordings_url, params: params
      end
    end

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>updated', 'true'

    m = r.metadata.find_by(key: 'gl-listed')
    assert_equal m.value, meta_params['gl-listed']
  end

  test 'updateRecordings deletes an existing meta parameter' do
    r = create(:recording_with_metadata, meta_params: { 'gl-listed' => 'true' })

    meta_params = { 'gl-listed' => '' }
    params = encode_bbb_params('updateRecordings', {
      recordID: r.record_id,
    }.merge(meta_params.transform_keys { |k| "meta_#{k}" }).to_query)

    assert_difference 'Metadatum.count', -1 do
      get bigbluebutton_api_update_recordings_url, params: params
    end

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>updated', 'true'

    assert_raises ActiveRecord::RecordNotFound do
      r.metadata.find_by!(key: 'gl-listed')
    end
  end

  test 'updateRecordings updates metadata on multiple recordings' do
    r1 = create(
      :recording_with_metadata,
      meta_params: { 'isBreakout' => 'false', 'meetingName' => "Fred's Room", 'gl-listed' => 'false' }
    )
    r2 = create(:recording)

    meta_params = { 'newkey' => 'newvalue', 'gl-listed' => '' }
    params = encode_bbb_params('updateRecordings', {
      recordID: "#{r1.record_id},#{r2.record_id}",
    }.merge(meta_params.transform_keys { |k| "meta_#{k}" }).to_query)

    # Add 2 metadata, delete 1 existing
    assert_difference(
      'r1.metadata.count' => 0,
      'r2.metadata.count' => 1,
      'Metadatum.count' => 1
    ) do
      get bigbluebutton_api_update_recordings_url, params: params
    end

    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>updated', 'true'

    assert_nil r1.metadata.find_by(key: 'gl-listed')
    assert_nil r2.metadata.find_by(key: 'gl-listed')
    assert_equal r1.metadata.find_by(key: 'newkey').value, 'newvalue'
    assert_equal r2.metadata.find_by(key: 'newkey').value, 'newvalue'
  end

  # deleteRecordings

  test 'deleteRecordings with no parameters returns checksum error' do
    get bigbluebutton_api_delete_recordings_url
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'deleteRecordings with invalid checksum returns checksum error' do
    get bigbluebutton_api_delete_recordings_url, params: "checksum=#{'x' * 40}"
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'checksumError'
  end

  test 'deleteRecordings requires recordID parameter' do
    params = encode_bbb_params('deleteRecordings', '')
    get bigbluebutton_api_delete_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'missingParamRecordID'
  end

  test 'deleteRecordings responds with notFound if passed invalid recordIDs' do
    params = encode_bbb_params('deleteRecordings', 'recordID=123')
    get bigbluebutton_api_delete_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'notFound'
  end

  test 'deleteRecordings deletes the recording from the database if passed recordID' do
    r = create(:recording, record_id: 'test123')

    params = encode_bbb_params('deleteRecordings', "recordID=#{r.record_id}")
    get bigbluebutton_api_delete_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>deleted', 'true'

    assert r.reload.state.eql?('deleted')
  end

  test 'deleteRecordings does not support POST requests' do
    r = create(:recording)

    params = encode_bbb_params('deleteRecordings', "recordID=#{r.record_id}")
    BigBlueButtonApiController.stub_any_instance(:verify_checksum, nil) do
      post bigbluebutton_api_delete_recordings_url, params: params
    end

    assert_response :success
    response_xml = Nokogiri.XML(response.body)
    expected_error = BBBErrors::UnsupportedRequestError.new
    assert_equal('FAILED', response_xml.at_xpath('/response/returncode').text)
    assert_equal(expected_error.message_key, response_xml.at_xpath('/response/messageKey').text)
    assert_equal(expected_error.message, response_xml.at_xpath('/response/message').text)
    r.reload
    assert_not_equal('deleted', r.state)
  end

  test 'deleteRecordings handles multiple recording IDs passed' do
    r = create(:recording)
    r1 = create(:recording)
    r2 = create(:recording)

    params = encode_bbb_params('deleteRecordings', { recordID: [r.record_id, r1.record_id, r2.record_id].join(',') }.to_query)
    get bigbluebutton_api_delete_recordings_url, params: params
    assert_response :success

    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>deleted', 'true'

    assert r.reload.state.eql?('deleted')
    assert r1.reload.state.eql?('deleted')
    assert r2.reload.state.eql?('deleted')
  end

  # RecordingDisabled

  test 'getRecordings returns noRecordings if RECORDING_DISABLED flag is set to true for a get request' do
    create_list(:recording, 3)
    params = encode_bbb_params('getRecordings', '')
    Rails.configuration.x.recording_disabled = true
    reload_routes!
    get bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>messageKey', 'noRecordings'
    assert_select 'response>message', 'There are not recordings for the meetings'
    Rails.configuration.x.recording_disabled = false
    reload_routes!
  end

  test 'getRecordings returns noRecordings if RECORDING_DISABLED flag is set to true for a post request' do
    create_list(:recording, 3)
    params = encode_bbb_params('getRecordings', '')
    Rails.configuration.x.recording_disabled = true
    reload_routes!
    post bigbluebutton_api_get_recordings_url, params: params
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>messageKey', 'noRecordings'
    assert_select 'response>message', 'There are not recordings for the meetings'
    Rails.configuration.x.recording_disabled = false
    reload_routes!
  end

  test 'publishRecordings returns notFound if RECORDING_DISABLED flag is set to true for a get request' do
    params = encode_bbb_params('publishRecordings', { publish: 'true' }.to_query)
    Rails.configuration.x.recording_disabled = true
    reload_routes!
    get 'http://www.example.com/bigbluebutton/api/publishRecordings', params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'notFound'
    assert_select 'response>message', 'We could not find recordings'
    Rails.configuration.x.recording_disabled = false
    reload_routes!
  end

  test 'publishRecordings does not support POST requests if RECORDING_DISABLED flag is set to true' do
    params = encode_bbb_params('publishRecordings', { publish: 'true' }.to_query)
    Rails.configuration.x.recording_disabled = true
    reload_routes!
    post 'http://www.example.com/bigbluebutton/api/publishRecordings', params: params

    assert_response :success
    response_xml = Nokogiri.XML(response.body)
    expected_error = BBBErrors::UnsupportedRequestError.new
    assert_equal('FAILED', response_xml.at_xpath('/response/returncode').text)
    assert_equal(expected_error.message_key, response_xml.at_xpath('/response/messageKey').text)
    assert_equal(expected_error.message, response_xml.at_xpath('/response/message').text)
    Rails.configuration.x.recording_disabled = false
    reload_routes!
  end

  test 'updateRecordings returns notFound if RECORDING_DISABLED flag is set to true for a get request' do
    params = encode_bbb_params('updateRecordings', '')
    Rails.configuration.x.recording_disabled = true
    reload_routes!
    get 'http://www.example.com/bigbluebutton/api/updateRecordings', params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'notFound'
    assert_select 'response>message', 'We could not find recordings'
    Rails.configuration.x.recording_disabled = false
    reload_routes!
  end

  test 'updateRecordings returns notFound if RECORDING_DISABLED flag is set to true for a post request' do
    params = encode_bbb_params('updateRecordings', '')
    Rails.configuration.x.recording_disabled = true
    reload_routes!
    post 'http://www.example.com/bigbluebutton/api/updateRecordings', params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'notFound'
    assert_select 'response>message', 'We could not find recordings'
    Rails.configuration.x.recording_disabled = false
    reload_routes!
  end

  test 'deleteRecordings returns notFound if RECORDING_DISABLED flag is set to TRUE for a get request' do
    r = create(:recording)
    params = encode_bbb_params('deleteRecordings', "recordID=#{r.record_id}")
    Rails.configuration.x.recording_disabled = true
    reload_routes!
    get 'http://www.example.com/bigbluebutton/api/deleteRecordings', params: params
    assert_response :success
    assert_select 'response>returncode', 'FAILED'
    assert_select 'response>messageKey', 'notFound'
    assert_select 'response>message', 'We could not find recordings'
    Rails.configuration.x.recording_disabled = false
    reload_routes!
  end

  test 'deleteRecordings does not support POST requests if RECORDING_DISABLED flag is set to TRUE' do
    r = create(:recording)
    params = encode_bbb_params('deleteRecordings', "recordID=#{r.record_id}")
    Rails.configuration.x.recording_disabled = true
    reload_routes!
    post 'http://www.example.com/bigbluebutton/api/deleteRecordings', params: params
    assert_response :success
    response_xml = Nokogiri.XML(response.body)
    expected_error = BBBErrors::UnsupportedRequestError.new
    assert_equal('FAILED', response_xml.at_xpath('/response/returncode').text)
    assert_equal(expected_error.message_key, response_xml.at_xpath('/response/messageKey').text)
    assert_equal(expected_error.message, response_xml.at_xpath('/response/message').text)
    Rails.configuration.x.recording_disabled = false
    reload_routes!
  end

  # get_meetings_api_disabled

  test 'getMeetings returns no meetings if GET_MEETINGS_API_DISABLED flag is set to true for a get request' do
    mock_env('GET_MEETINGS_API_DISABLED' => 'TRUE') do
      reload_routes!
      get bigbluebutton_api_get_meetings_url
    end
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>messageKey', 'noMeetings'
    assert_select 'response>message', 'no meetings were found on this server'
    assert_select 'response>meetings', ''
  end

  test 'getMeetings returns no meetings if GET_MEETINGS_API_DISABLED flag is set to true for a post request' do
    mock_env('GET_MEETINGS_API_DISABLED' => 'TRUE') do
      reload_routes!
      post bigbluebutton_api_get_meetings_url
    end
    assert_response :success
    assert_select 'response>returncode', 'SUCCESS'
    assert_select 'response>messageKey', 'noMeetings'
    assert_select 'response>message', 'no meetings were found on this server'
    assert_select 'response>meetings', ''
  end
end
