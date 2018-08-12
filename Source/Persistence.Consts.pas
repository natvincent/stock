unit Persistence.Consts;

interface

const
  CMissingFieldsMessage = 'A list of fields must be provided to be able to generate an SQL statement.';
  CMissingFromMessage = 'You must provide a from table to be able to generate a select statement.';
  CMissingIntoUpdateMessage = 'You must provide a table to be able to generate an insert statement.';
  CWhereFieldsNotSupported = 'Where fields are not supported for insert statements.';

implementation

end.
