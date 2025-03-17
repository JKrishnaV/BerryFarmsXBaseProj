using System.ComponentModel.DataAnnotations;

namespace WpfGrowersApp.Models
{
    public class Grower
    {
        [Key]
        public int Id { get; set; }

        [Required]
        [StringLength(100)]
        public string Name { get; set; }

        [StringLength(100)]
        public string ChequeName { get; set; }

        [Required]
        public string Address { get; set; }

        [StringLength(50)]
        public string City { get; set; }

        [StringLength(10)]
        public string Province { get; set; }

        [StringLength(20)]
        public string PostalCode { get; set; }

        [Phone]
        public string Phone { get; set; }

        public double Acres { get; set; }

        public bool OnHold { get; set; }

        public string Notes { get; set; }
    }
}