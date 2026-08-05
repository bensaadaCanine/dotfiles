local commands = require 'kubectl.actions.commands'
local ingress_view = require 'kubectl.views.ingresses'
local mappings = require 'kubectl.mappings'

vim.schedule(function()
  vim.api.nvim_buf_set_keymap(0, 'n', '<Plug>(kubectl.ingress_aws)', '', {
    noremap = true,
    silent = true,
    desc = 'Open AWS Console for the ingress ALB',
    callback = function()
      local name, ns = ingress_view.getCurrentSelection()
      vim.notify('checking DNS of ingress ' .. name)
      commands.shell_command_async('kubectl', {
        'get',
        'ingress',
        name,
        '-n',
        ns,
        '-o',
        "jsonpath='{.status.loadBalancer.ingress[*].hostname}'",
      }, function(ingress_dns)
        -- remove surrounding quotes from ingress_dns
        ingress_dns = string.sub(ingress_dns, 2, -2)
        vim.schedule(function()
          local cluster_name = require('kubectl.state').context['current-context']
          -- Resolve the AWS profile from the environment/CLI config instead of a
          -- hardcoded cluster-name map, so this works for any cluster/account.
          local aws_profile = os.getenv 'AWS_PROFILE' or 'default'
          local region = os.getenv 'AWS_REGION' or vim.trim(commands.shell_command('aws', { 'configure', 'get', 'region', '--profile', aws_profile }))
          vim.notify(ingress_dns)
          vim.notify('cluster: ' .. cluster_name .. ' AWS_PROFILE: ' .. aws_profile .. ' AWS_REGION: ' .. region)
          local aws_cmd = {
            'elbv2',
            'describe-load-balancers',
            '--query',
            string.format('LoadBalancers[?DNSName==`%s`]', ingress_dns),
            '--profile',
            aws_profile,
            '--output',
            'json',
          }
          commands.shell_command_async('aws', aws_cmd, function(aws_output)
            local ok
            ok, aws_output = pcall(vim.json.decode, aws_output)
            if not ok then
              vim.notify('Failed to parse AWS output\n' .. aws_output)
              return
            end
            if vim.tbl_count(aws_output) == 0 then
              vim.notify('ALB not found for DNS ' .. ingress_dns)
              return
            end
            local alb_arn = aws_output and aws_output[1].LoadBalancerArn
            local lb_url =
              string.format('https://%s.console.aws.amazon.com/ec2/home?region=%s#LoadBalancer:loadBalancerArn=%s;tab=listenersb', region, region, alb_arn)
            vim.schedule(function()
              -- Optional: set $AWS_SSO_URL to your org's SSO portal to be prompted
              -- to open it (e.g. to refresh a session) before the AWS console link.
              local sso_url = os.getenv 'AWS_SSO_URL'
              if not sso_url then
                vim.ui.open(lb_url)
                return
              end
              vim.ui.select({ 'Yes', 'No' }, { title = 'Open SSO portal before AWS console?' }, function(choice)
                if not choice or choice == 'No' then
                  vim.ui.open(lb_url)
                  return
                end
                vim.ui.open(sso_url)
                vim.defer_fn(function()
                  vim.ui.open(lb_url)
                end, 3000)
              end)
            end)
          end)
        end)
      end)
    end,
  })
end)

vim.schedule(function()
  mappings.map_if_plug_not_set('n', 'gi', '<Plug>(kubectl.ingress_aws)')
end)
