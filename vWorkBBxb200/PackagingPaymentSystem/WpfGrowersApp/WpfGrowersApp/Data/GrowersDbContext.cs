using Microsoft.EntityFrameworkCore;

namespace WpfGrowersApp.Data
{
    public class GrowersDbContext : DbContext
    {
        public GrowersDbContext(DbContextOptions<GrowersDbContext> options) : base(options)
        {
        }

        public DbSet<Grower> Growers { get; set; }

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            modelBuilder.Entity<Grower>().ToTable("Growers");
            // Additional model configuration can be added here
        }
    }
}