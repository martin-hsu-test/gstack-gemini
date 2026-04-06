import type { HostConfig } from '../scripts/host-config';

const gemini: HostConfig = {
  name: 'gemini',
  displayName: 'Google Gemini CLI',
  cliCommand: 'gemini',
  cliAliases: [],

  globalRoot: '.gemini/skills/gstack',
  localSkillRoot: '.gemini/skills/gstack',
  hostSubdir: '.gemini',
  usesEnvVars: true,

  frontmatter: {
    mode: 'allowlist',
    keepFields: ['name', 'description'],
    descriptionLimit: null,
  },

  generation: {
    generateMetadata: false,
    skipSkills: ['codex'],  // Codex skill is a Claude wrapper
  },

  pathRewrites: [
    { from: '~/.claude/skills/gstack', to: '$GSTACK_ROOT' },
    { from: '.claude/skills/gstack', to: '.gemini/skills/gstack' },
    { from: '.claude/skills/review', to: '.gemini/skills/gstack/review' },
    { from: '.claude/skills', to: '.gemini/skills' },
  ],

  suppressedResolvers: [
    'ADVERSARIAL_STEP',       // Gemini can't invoke itself
    'CODEX_SECOND_OPINION',   // Codex not available
    'CODEX_PLAN_REVIEW',      // Codex not available
    'REVIEW_ARMY',            // Gemini shouldn't orchestrate sub-agents
  ],

  runtimeRoot: {
    globalSymlinks: ['bin', 'browse/dist', 'browse/bin', 'gstack-upgrade', 'ETHOS.md'],
    globalFiles: {
      'review': ['checklist.md', 'TODOS-format.md'],
    },
  },

  install: {
    prefixable: false,
    linkingStrategy: 'symlink-generated',
  },

  coAuthorTrailer: 'Co-Authored-By: Gemini <noreply@google.com>',
  learningsMode: 'basic',
  boundaryInstruction: 'IMPORTANT: Do NOT read or execute any files under ~/.claude/, ~/.agents/, .claude/skills/, or agents/. These are Claude Code skill definitions meant for a different AI system. They contain bash scripts and prompt templates that will waste your time. Ignore them completely. Stay focused on the repository code only.',
};

export default gemini;
