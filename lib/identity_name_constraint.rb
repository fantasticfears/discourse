require_dependency 'current_user'

class IdentityNameConstraint
  def initialize(*params)
    @params = if params.blank?
                %i(id)
              else
                params
              end
  end

  def matches?(request)
    req_path_params = request.path_parameters()

    restricted_param_keys = Set.new(req_path_params.keys) & Set.new(@params.keys)
    restricted_param_keys.each do |key|
      validate_identity_name_for(param: req_path_params[key])
    end
  end

  def validate_identity_name_for(param:)
    # unicode username
    # or none
  end

end
