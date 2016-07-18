require 'rails_helper'

describe WebHookEvent do
  let(:event) { Fabricate(:web_hook_event) }
  let(:failed_event) { Fabricate(:web_hook_event, status: 400) }

  it 'update last delivery status for associated WebHook record' do
    event.save!
    expect(event.web_hook.last_delivery_status).to eq(WebHook.last_delivery_statuses[:successful])
  end

  it 'sets last delivery status to failed' do
    failed_event.save!
    expect(failed_event.web_hook.last_delivery_status).to eq(WebHook.last_delivery_statuses[:failed])
  end
end
