disabled_services(node).each do |svc|

  supervisor_service "service-#{svc[:name]}" do
    action service_is_up?(node, "service-#{svc[:name]}") ? [:stop, :disable] : [:disable]
  end
end
