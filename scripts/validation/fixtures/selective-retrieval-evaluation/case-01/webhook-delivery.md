# Webhook delivery ownership

The `WebhookDeliveryService` owns outbound delivery retries. It retries transient HTTP failures up to five attempts with exponential backoff.
