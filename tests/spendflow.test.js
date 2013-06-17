var assert = require('assert');
var _ = require('underscore');

suite('Basic setup', function () {
  test('accounting.js exists', function (done, server, client) {
    client.eval(function () {
      emit('done', accounting);
    }).once('done', function (accountingObject) {
        if (! accountingObject) {
          // Make it fail test without ReferenceError
          accountingObject = null;
        }
        assert.equal(_.isObject(accountingObject), true);
        done();
      });
  });
});
