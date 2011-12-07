using System;

namespace RubyODataService.Models
{
    public class Product
    {
        public Product()
        {
            AuditFields = new AuditFields();
        }
        public int Id { get; set; }
        public string Name { get; set; }
        public string Description { get; set; }
        public decimal Price { get; set; }
        public DateTime? DiscontinuedDate { get; set; }
        public int CategoryId { get; set; }
        public Category Category { get; set; }
        public AuditFields AuditFields { get; set; }
    }
}