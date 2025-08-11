#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const readline = require('readline');

// Constants
const COMPACTION_THRESHOLD = 200000 * 0.8; // 160,000 tokens

// Read JSON from stdin
let input = '';
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', async () => {
  try {
    const data = JSON.parse(input);
    const sessionId = data.session_id;

    if (!sessionId) {
      console.log('');
      return;
    }

    // Find transcript file
    const projectsDir = path.join(process.env.HOME, '.claude', 'projects');
    
    if (!fs.existsSync(projectsDir)) {
      console.log('');
      return;
    }

    // Search for the current session's transcript file
    const projectDirs = fs.readdirSync(projectsDir)
      .map(dir => path.join(projectsDir, dir))
      .filter(dir => fs.statSync(dir).isDirectory());

    let totalTokens = 0;
    for (const projectDir of projectDirs) {
      const transcriptFile = path.join(projectDir, `${sessionId}.jsonl`);
      
      if (fs.existsSync(transcriptFile)) {
        totalTokens = await calculateTokensFromTranscript(transcriptFile);
        break;
      }
    }

    // Calculate percentage
    const percentage = Math.min(100, Math.round((totalTokens / COMPACTION_THRESHOLD) * 100));
    
    // Format token display
    const tokenDisplay = formatTokenCount(totalTokens);
    
    // Output format: tokens|percentage
    console.log(`${tokenDisplay}|${percentage}`);
  } catch (error) {
    console.log('');
  }
});

async function calculateTokensFromTranscript(filePath) {
  return new Promise((resolve, reject) => {
    let lastUsage = null;

    const fileStream = fs.createReadStream(filePath);
    const rl = readline.createInterface({
      input: fileStream,
      crlfDelay: Infinity
    });

    rl.on('line', (line) => {
      try {
        const entry = JSON.parse(line);
        
        // Check if this is an assistant message with usage data
        if (entry.type === 'assistant' && entry.message?.usage) {
          lastUsage = entry.message.usage;
        }
      } catch (e) {
        // Skip invalid JSON lines
      }
    });

    rl.on('close', () => {
      if (lastUsage) {
        // The last usage entry contains cumulative tokens
        const totalTokens = (lastUsage.input_tokens || 0) +
          (lastUsage.output_tokens || 0) +
          (lastUsage.cache_creation_input_tokens || 0) +
          (lastUsage.cache_read_input_tokens || 0);
        resolve(totalTokens);
      } else {
        resolve(0);
      }
    });

    rl.on('error', (err) => {
      resolve(0);
    });
  });
}

function formatTokenCount(tokens) {
  if (tokens >= 1000000) {
    return `${(tokens / 1000000).toFixed(1)}M`;
  } else if (tokens >= 1000) {
    return `${(tokens / 1000).toFixed(1)}K`;
  }
  return tokens.toString();
}