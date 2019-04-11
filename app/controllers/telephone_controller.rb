require "google/cloud/translate"
require "google/cloud/speech"

class TelephoneController < ApplicationController
    skip_before_action :verify_authenticity_token

    BASE_URL = ""
    GOOGLE_PROJECT_ID = "nexmo-rails-telephone-game"
    Translator = Google::Cloud::Translate.new project: GOOGLE_PROJECT_ID
    NexmoClient = Nexmo::Client.new(
        application_id: ENV['NEXMO_APPLICATION_ID'],
        private_key: File.read(ENV['NEXMO_PRIVATE_KEY'])
        ) 
    NexmoClient.calls.instance_variable_set(:@host, 'api-us-1.nexmo.com')
    Converter = Google::Cloud::Speech.new
    LANGUAGES = [
        'ar',
        'he',
        'hi',
        'ku',
        'ru',
        'tr',
        'yi'
    ]

    def answer
        puts "Starting Call"
        @@uuid = params[:uuid]
        render json:
        [
            { 
                :action => 'talk', 
                :text => 'Welcome to the Nexmo Telephone Game. To begin say your message at the beep. To end the recording press the pound key.'
            },
            {
                :action => 'record',
                :eventUrl => ["#{BASE_URL}/event"],
                :beepStart => true,
                :format => "wav",
                :endOnKey => "#",
                :timeOut => 30
            },
            {
                :action => 'talk',
                :text => 'Please wait a moment...'
            },
            {
                :action => 'conversation',
                :name => 'telephone-game-conversation'
            }
        ].to_json
    end

    def event
        if params['recording_url']
            # Save Recording
            puts "Saving Audio File"
            NexmoClient.files.save(params['recording_url'], 'recording.wav')

            # Transcribe Recording
            transcribed_text = ''
            file_name = './recording.wav'
            audio_file = File.binread(file_name)
            config = { 
                sample_rate_hertz: 16000,
                language_code: "en-US"   
            }
            audio = { content: audio_file } 
            puts "Converting Speech to Text with GCP Speech API"
            response = Converter.recognize(config, audio)
            results = response.results
            results.first.alternatives.each do |alternatives|
               transcribed_text = alternatives.transcript
            end

            # Run Transcription Through Translations
            final_translation = ''
            current_translation = ''
            first_time = true
            LANGUAGES.each do |language|
                if current_translation = '' && first_time = true
                    current_translation = Translator.translate(transcribed_text, to: language)
                    first_time = false
                else
                    previous_translation = current_translation
                    current_translation = Translator.translate(previous_translation, to: language)
                end
            end
            final_translation = Translator.translate(current_translation.text, to: 'en')

            # Play Final Text Back To Call
            puts "Playing Transcribed Audio to Call"
            closing_msg = "Your message was translated through Arabic, Hebrew, Hindi, Kurdish, Russian, Turkish and Yiddish and is returned to you as: #{final_translation.text}"
            NexmoClient.calls.talk.start(@@uuid, text: closing_msg, voice_name: "Kimberly") if transcribed_text != ''
        end
    end
end
