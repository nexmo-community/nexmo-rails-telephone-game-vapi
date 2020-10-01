# Rails Telephone Game with Vonage (previously Nexmo) Voice API

This is the classic game of telephone reimagined as a Rails application utilizing the Vonage Voice API along with Google Cloud Platform Speech to Text and Translate APIs.

## Prerequisites

This project requires the following:

* Ruby
* Rails
* A Vonage Account
* A Vonage Phone Number
* Google Cloud Platform account
* ngrok

## Installation

To install the application:

* Clone this repository locally
* Run `bundle install` and `rake db:migrate` to set up the Rails application

## Usage

To run the telephone game do the following:

* Rename `.env.sample` to `.env` and insert your Vonage and Google API credentials, along with your Vonage phone number
* Download and install ngrok locally, if you have not done so already
* Start your ngrok server by running `ngrok http 3000` from the command line
* Add your ngrok URL to the `BASE_URL` constant in `/app/controllers/telephone_controller.rb`
* Start your Rails server by running `rails s` from the command line
* Dial your Vonage phone number and follow along in the phone instructions to play!

## License

This project is under the [MIT License](LICENSE).