module.exports = {
  default: {
    requireModule: ['ts-node/register'],
    require: ['steps/**/*.ts'],
    format: ['progress', 'html:cucumber-report.html'],
    formatOptions: { snippetInterface: 'async-await' },
  }
};