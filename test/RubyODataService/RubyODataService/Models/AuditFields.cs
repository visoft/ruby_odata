using System;

namespace RubyODataService.Models
{
    public class AuditFields
    {
        public AuditFields()
        {
            CreateDate = DateTime.UtcNow;
            ModifiedDate = DateTime.UtcNow;
        }
        public DateTime CreateDate { get; set; }
        public DateTime ModifiedDate { get; set; }
        public string CreatedBy { get; set; }
    }
}