using System.Collections.Generic;

namespace RubyODataService.Models
{
    public class Category
    {
        public Category()
        {
            AuditFields = new AuditFields();
        }
        public int Id { get; set; }
        public string Name { get; set; }
        public virtual ICollection<Product> Products { get; set; }
        public AuditFields AuditFields { get; set; }
    }
}