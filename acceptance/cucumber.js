module.exports = {
  default: function () {
    // Load step definitions
    require('./steps/api.steps.ts');
    require('./steps/author.steps.ts');
    require('./steps/customer.steps.ts');
    require('./steps/delivery.steps.ts');
    require('./steps/reporting.steps.ts');
    require('./steps/stream.steps.ts');
    require('./steps/validation.steps.ts');
  }
};