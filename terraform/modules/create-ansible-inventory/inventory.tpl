%{ for name, ips in servers ~}
${name}:
  hosts:
%{ for ip in ips ~}
    ${ip}:
%{ endfor ~}
%{ endfor ~}