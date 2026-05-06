local layouts = require("agent_term.layouts")

return {
  config = layouts.claude_pair_config,
  open = layouts.open_agent_claude_pair,
  cycle_forward = layouts.cycle_forward,
  cycle_backward = layouts.cycle_backward,
}
