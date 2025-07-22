using Microsoft.AspNetCore.Components.Web;
using Microsoft.AspNetCore.Components.WebAssembly.Hosting;
using DoggyLife;
using DoggyLife.Data.Database;
using SqliteWasmHelper;
using Microsoft.EntityFrameworkCore;
using DoggyLife.Services;

var builder = WebAssemblyHostBuilder.CreateDefault(args);
builder.RootComponents.Add<App>("#app");
builder.RootComponents.Add<HeadOutlet>("head::after");

builder.Services.AddSingleton<MusicService>();
builder.Services.AddSingleton<RoomService>();
builder.Services.AddSingleton<HologramItemService>();

builder.Services.AddSqliteWasmDbContextFactory<AppDbContext>(
  opts => opts.UseSqlite("Data Source=things.sqlite3"));

builder.Services.AddScoped(_ => new HttpClient { BaseAddress = new Uri(builder.HostEnvironment.BaseAddress) });

var host = builder.Build();

await host.RunAsync();
