Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/answer', to: 'telephone#answer'
  post '/event', to: 'telephone#event'
  get '/translate', to: 'telephone#translate'
end
