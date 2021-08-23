module.exports = {
  'env': {
    'browser': true,
    'commonjs': true,
    'es2021': true
  },
  'parserOptions': {
    'ecmaVersion': 12
  },
  'rules': {
    'array-bracket-spacing': ['error', 'never'],
    'brace-style': ['error', '1tbs', { 'allowSingleLine': true }],
    'eqeqeq': ['error', 'always'],
    'indent': ['error', 2],
    'keyword-spacing': ['error', { 'before': true, 'after': true }],
    'linebreak-style': ['error', 'unix'],
    'no-console': 'warn',
    'no-trailing-spaces': 'error',
    'object-curly-spacing': ['error', 'always'],
    'quotes': ['error', 'single'],
    'semi': ['error', 'never'],
    'space-before-blocks': ['error', 'always'],
    'space-before-function-paren': ['error', 'always'],
    'space-infix-ops': 'error',
    'spaced-comment': ['error', 'always']
  }
}
