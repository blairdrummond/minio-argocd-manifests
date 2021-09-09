package httpapi.authz
import input

# For environment variables
runtime := opa.runtime()

default allow = false

rl_permissions := {
    "reader": [{"action": "s3:ListBucket"},
              {"action": "s3:GetObject"},
              {"action": "s3:ListAllMyBuckets"}],
    "user": [{"action": "s3:CreateBucket"},
             {"action": "s3:DeleteBucket"},
             {"action": "s3:DeleteObject"},
             {"action": "s3:GetObject"},
             {"action": "s3:ListAllMyBuckets"},
             {"action": "s3:GetBucketObjectLockConfiguration"},
             {"action": "s3:ListBucket"},
             {"action": "s3:PutObject"}],
    "shared": [{"action": "s3:ListAllMyBuckets"},
               {"action": "s3:GetObject"},
               {"action": "s3:ListBucket" }],
    "vault": [{"action": "s3:ListAllMyBuckets"},
              {"action": "s3:CreateBucket"},
              {"action": "s3:DeleteBucket"},
              {"action": "admin:CreatePolicy"},
              {"action": "admin:DeletePolicy"},
              {"action": "admin:GetPolicy"},
              {"action": "admin:AttachUserOrGroupPolicy"},
              {"action": "admin:ListUserPolicies"},
              {"action": "admin:EnableUser"},
              {"action": "admin:DisableUser"},
              {"action": "s3:PutObject"},
              {"action": "admin:GetUser"}],
}

##
## PRIVATE BUCKETS
##

# Tokens generated by Vault
allow {
  profile := regex.find_all_string_submatch_n("^profile-(.*)-[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$", input.account, 1)
  input.bucket == profile[0][1]
  permissions := rl_permissions["user"]
  p := permissions[_]
  p == {"action": input.action}
}

##
## SHARED BUCKET
##

# Tokens generated by Vault
allow {
  profile := regex.find_all_string_submatch_n("^profile-(.*)-[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}$", input.account, 1)
  username = profile[0][1]
  input.bucket == "shared"
  url := concat("/", [username,".*$"] )
  re_match(url , input.object)
  permissions := rl_permissions["user"]
  p := permissions[_]
  p == {"action": input.action}
}

# Allow other shared permissions to all users
allow {
  input.bucket == "shared"
  permissions := rl_permissions["shared"]
  p := permissions[_]
  p == {"action": input.action}
}

##
## ADMIN
##

trace(input)

# Needed by Vault to create profiles
allow {
  input.account == runtime.env.MINIO_ADMIN
  permissions := rl_permissions["vault"]
  p := permissions[_]
  p == {"action": input.action}
}
