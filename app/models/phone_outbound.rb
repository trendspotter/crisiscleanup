class PhoneOutbound < ActiveRecord::Base
  self.table_name = 'phone_outbound'
  belongs_to :legacy_site, class_name: "Legacy::LegacySite", foreign_key: "worksite_id"
    
  def self.get_locked_call_for_user(current_user_id)
    return self.joins("LEFT OUTER JOIN phone_area_codes ON phone_area_codes.code = phone_outbound.dnis1_area_code")
        .select('phone_outbound.id,
                 phone_outbound.dnis1,
                 phone_outbound.dnis2,
                 phone_area_codes.location,
                 phone_outbound.inbound_at,
                 phone_outbound.case_updated_at,
                 phone_outbound.vm_link,
                 phone_outbound.worksite_id,
                 phone_outbound.call_type,
                 phone_outbound.completion')
        .where(id: PhoneOutboundStatus.select('outbound_id').where(
          user_id: current_user_id, status_id: [false, nil])).order(:created_at).first    
  end
  
  ####
  # For Testing
  # AND phone_outbound.dnis2 IS NOT NULL
  # current_user_id).order("random()", :call_type, :inbound_at, :case_updated_at).first 
  
  def self.select_next_phone_outbound_for_user(current_user_id)
    return self.where("phone_outbound.id NOT IN 
      (
        SELECT outbound_id FROM phone_outbound_status
        WHERE (do_not_call_before > NOW() 
          OR do_not_call_before IS NULL)
        AND outbound_id IS NOT NULL)
      AND (DATE_PART('day', NOW() - case_updated_at) > 5
        OR DATE_PART('day', NOW() - case_updated_at) IS NULL)
      AND (phone_outbound.completion < 1 OR phone_outbound.completion IS NULL)").order(:call_type, :inbound_at, :case_updated_at).first
  end
      
  def self.remaining_callbacks
    return self.where("phone_outbound.id NOT IN (
    SELECT outbound_id FROM phone_outbound_status
      WHERE user_id IS NOT NULL
      AND (do_not_call_before > NOW()
        OR do_not_call_before IS NULL)
      AND outbound_id IS NOT NULL)
    AND (DATE_PART('day', NOW() - case_updated_at) > 5
      OR DATE_PART('day', NOW() - case_updated_at) IS NULL)
    AND (phone_outbound.completion < 1 OR phone_outbound.completion IS NULL)
    AND call_type = 'callback'  
    ").count
  end
  
  def self.remaining_calldowns
    return self.where("phone_outbound.id NOT IN (
    SELECT outbound_id FROM phone_outbound_status
      WHERE user_id IS NOT NULL
      AND (do_not_call_before > NOW()
        OR do_not_call_before IS NULL)
      AND outbound_id IS NOT NULL)
    AND (DATE_PART('day', NOW() - case_updated_at) > 5
      OR DATE_PART('day', NOW() - case_updated_at) IS NULL)
    AND (phone_outbound.completion < 1 OR phone_outbound.completion IS NULL)
    AND call_type = 'calldown'  
    ").count
  end  
  
end
