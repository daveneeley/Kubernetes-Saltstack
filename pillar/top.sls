base:
  'role:k8s-(master|worker)':
    - match: grain_pcre
    - cluster_config
