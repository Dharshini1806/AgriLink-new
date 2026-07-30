/**
 * Joi validation middleware factory
 * @param {import('joi').Schema} schema
 * @param {'body'|'query'|'params'} source
 */
const validate = (schema, source = 'body') => (req, res, next) => {
  const { error, value } = schema.validate(req[source], {
    abortEarly: false,
    stripUnknown: true,
    convert: true,
  });
  if (error) {
    const details = error.details.map(d => d.message);
    return res.status(422).json({ error: 'Validation failed', details });
  }
  req[source] = value;
  next();
};

module.exports = validate;
