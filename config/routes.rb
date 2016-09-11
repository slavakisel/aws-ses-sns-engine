AwsSesSnsEngine::Engine.routes.draw do
  resource :sns, only: :post do
    post :sns_endpoint
  end
end
