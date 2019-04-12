require "google/cloud/translate"
require "google/cloud/speech"

class TelephoneController < ApplicationController
    skip_before_action :verify_authenticity_token

    Translator = Google::Cloud::Translate.new project: ENV['GOOGLE_PROJECT_ID']
    Nexmo::CallTalk.host = 'api-us-1.nexmo.com'
    NexmoClient = Nexmo::Client.new(
        application_id: ENV['NEXMO_APPLICATION_ID'],
        private_key: File.read(ENV['NEXMO_PRIVATE_KEY'])
        ) 
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
                :eventUrl => ["#{ENV['BASE_URL']}/event"],
                :beepStart => true,
                :format => "wav",
                :endOnKey => "#",
                :timeOut => 30
            },
            {
                :action => 'talk',
                :text => 'Please wait a moment as your message runs through our sophisticated top secret linguistic algorithm...'
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
            audio_content  = File.binread(file_name)
            bytes_total    = audio_content.size
            bytes_sent     = 0
            chunk_size     = 32000
            streaming_config = {
                config: {
                    encoding: :LINEAR16,
                    sample_rate_hertz: 16000,
                    language_code: "en-US",
                    enable_word_time_offsets: true     
                },
                interim_results: true
            }
            puts "Converting Speech to Text with GCP Speech API"
            stream = Converter.streaming_recognize(streaming_config)
            # Simulated streaming from a microphone
            # Stream bytes...
            while bytes_sent < bytes_total do
                stream.send audio_content[bytes_sent, chunk_size]
                bytes_sent += chunk_size
                sleep 1
            end
            puts "Stopped passing audio to be transcribed"
            stream.stop
            # Wait until processing is complete...
            stream.wait_until_complete!
            puts "Transcription processing complete"
            results = stream.results
            results.first.alternatives.each do |alternatives|
               transcribed_text = alternatives.transcript
            end

            # Run Transcription Through Translations
            puts "Translating Message"
            translated_text = transcribed_text
            LANGUAGES.each do |language|
                translated_text = (translated_text == transcribed_text) ? 
                Translator.translate(translated_text, to: language) : Translator.translate(translated_text.text, to: language)
            end
            final_translation = Translator.translate(translated_text.text, to: 'en')

            # Play Final Text Back To Call
            puts "Playing Translated Audio to Call"
            puts "Transcribed Original Message: #{transcribed_text}"
            puts "Final Message: #{final_translation.text}"
            closing_msg = "Your message was translated through Arabic, Hebrew, Hindi, Kurdish, Russian, Turkish and Yiddish and is returned to you as: #{final_translation.text}"
            NexmoClient.calls.talk.instance_variable_set(:@host, 'api-us-1.nexmo.com')
            NexmoClient.calls.talk.start(@@uuid, text: closing_msg, voice_name: "Kimberly") if transcribed_text != ''
        end
    end
end
