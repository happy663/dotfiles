local layouts = require("agent_term.layouts")

return {
  config = layouts.dual_claude_config,
  open = layouts.open_dual_claude,
  cycle_forward = layouts.cycle_forward,
  cycle_backward = layouts.cycle_backward,
}
