disabled_services(node).each do |svc|

  supervisor_service "service-#{svc[:service_name]}" do
    action service_is_up?(node, "service-#{svc[:service_name]}") ? [:stop, :disable] : [:disable]
  end
end
