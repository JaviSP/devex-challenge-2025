# Delete runner

# 0. Validate request header `X-Hub-Signature-256` to ensure the request is from GitHub`
# 1. Check body message to differentiate between create and delete runner actions
# 2. If create, body should contains "action: queue"
# 2.1. Call Github API to create the JIT config
# 2.3. Create the EC2 spot instance
# 3. If delete, check if the runner is already deleted
# 3.1. Terminate the proper EC2 instance base on body message (runner_id)