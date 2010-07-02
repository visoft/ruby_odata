using System;

namespace Model
{
	public partial class AuditFields
	{
		public AuditFields()
		{
			CreateDate = DateTime.UtcNow;
			ModifiedDate = DateTime.UtcNow;
		}
	}
}