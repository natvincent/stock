unit Persistence.Consts;

interface

const
  CMissingFieldsMessage = 'A list of fields must be provided to be able to generate an SQL statement.';
  CMissingFromMessage = 'You must provide a from table to be able to generate a select statement.';
  CMissingIntoUpdateMessage = 'You must provide a table to be able to generate an insert statement.';
  CWhereFieldsNotSupported = 'Where fields are not supported for insert statements.';

  CTableNameAttributeNotFound = 'The class %s must be decorated with a TableName attribute.';

  COnlyOneIdentityPropertyAllowed = 'Only one field per class can be decorated with the "Identity" attribute.';
  CMustHaveIntegerIdentityProperty = 'The type %s does not have an integer identity column and therefor cannot be loaded.';

  CDatabasePathNotSet = 'You must set the database path on the connection factory before you can create a connection.';

implementation

end.
