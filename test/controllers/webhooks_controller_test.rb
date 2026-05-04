require "test_helper"

class WebhooksControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :subscriptions

  # Minitest 6 a supprimé Object#stub — on patche/dépache manuellement.
  def with_stripe_event(event_or_exception)
    original = Stripe::Webhook.method(:construct_event)
    Stripe::Webhook.define_singleton_method(:construct_event) do |*_args|
      raise event_or_exception if event_or_exception.is_a?(Exception)
      event_or_exception
    end
    yield
  ensure
    Stripe::Webhook.define_singleton_method(:construct_event, original)
  end

  def post_stripe_event(type, data_object)
    fake_event = { "type" => type, "data" => { "object" => data_object } }
    with_stripe_event(fake_event) do
      post webhooks_stripe_url,
           params: "{}",
           headers: { "CONTENT_TYPE" => "application/json",
                      "HTTP_STRIPE_SIGNATURE" => "t=fake,v1=fake" }
    end
  end

  # ===================================================================
  # checkout.session.completed
  # ===================================================================

  test "checkout.session.completed saves stripe_customer_id on user" do
    user = users(:freemium_user)
    user.update_column(:stripe_customer_id, nil)

    post_stripe_event("checkout.session.completed", {
      "id"       => "cs_test_checkout",
      "customer" => "cus_new_from_checkout",
      "metadata" => { "user_id" => user.id.to_s, "tier" => "individual" }
    })

    assert_response :success
    assert_equal "cus_new_from_checkout", user.reload.stripe_customer_id
  end

  test "checkout.session.completed returns 200 even if user not found" do
    post_stripe_event("checkout.session.completed", {
      "id"       => "cs_test_unknown",
      "customer" => "cus_unknown",
      "metadata" => { "user_id" => "999999", "tier" => "individual" }
    })
    assert_response :success
  end

  # ===================================================================
  # customer.subscription.created
  # ===================================================================

  test "subscription.created creates active subscription for user" do
    user = users(:freemium_user)
    assert_equal "freemium", user.subscription_tier

    post_stripe_event("customer.subscription.created", {
      "id"                   => "sub_brand_new",
      "customer"             => user.stripe_customer_id,
      "status"               => "active",
      "metadata"             => { "tier" => "individual" },
      "items"                => { "data" => [] },
      "current_period_start" => 1.month.ago.to_i,
      "current_period_end"   => 1.month.from_now.to_i
    })

    assert_response :success
    user.reload
    assert_equal "individual", user.subscription_tier
    assert user.subscriptions.active.exists?
  end

  # ===================================================================
  # customer.subscription.deleted
  # ===================================================================

  test "subscription.deleted sets subscription status to canceled" do
    subscription = subscriptions(:individual_subscription)
    assert subscription.active?

    post_stripe_event("customer.subscription.deleted", {
      "id" => subscription.stripe_subscription_id
    })

    assert_response :success
    assert_equal "canceled", subscription.reload.status
  end

  # ===================================================================
  # invoice.payment_failed
  # ===================================================================

  test "invoice.payment_failed enqueues payment failure email" do
    subscription = subscriptions(:individual_subscription)

    assert_emails 1 do
      post_stripe_event("invoice.payment_failed", {
        "id"           => "in_failed_test",
        "subscription" => subscription.stripe_subscription_id
      })
    end

    assert_response :success
  end

  # ===================================================================
  # Signature invalide
  # ===================================================================

  test "rejects request with invalid stripe signature" do
    with_stripe_event(Stripe::SignatureVerificationError.new("bad sig", "header")) do
      post webhooks_stripe_url,
           params: "{}",
           headers: { "CONTENT_TYPE" => "application/json",
                      "HTTP_STRIPE_SIGNATURE" => "invalid" }
    end
    assert_response :bad_request
  end

  # ===================================================================
  # Payload invalide
  # ===================================================================

  test "rejects request with unparseable JSON payload" do
    with_stripe_event(JSON::ParserError.new("invalid json")) do
      post webhooks_stripe_url,
           params: "{}",
           headers: { "CONTENT_TYPE" => "application/json",
                      "HTTP_STRIPE_SIGNATURE" => "t=fake,v1=fake" }
    end
    assert_response :bad_request
  end
end
