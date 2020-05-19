native: self: super:
let dds = x: x.overrideAttrs (o: { dontDisableStatic = true; });
in {
  buildPackages = super.buildPackages // { inherit (native) rakudo; };
  ocaml = self.ocaml-ng.ocamlPackages_4_07.ocaml;
  libev = dds super.libev;
  libusb = self.libusb1;
  systemd = self.eudev;
  libusb1 = dds (super.libusb1.override {
    enableSystemd = true;
  });
  gdb = null;
  hidapi = dds (super.hidapi.override { systemd = self.eudev; });
  glib = (super.glib.override { libselinux = null; }).overrideAttrs
    (o: { mesonFlags = o.mesonFlags ++ [ "-Dselinux=disabled" ]; });
  eudev = dds (super.eudev.overrideAttrs
    (o: { nativeBuildInputs = o.nativeBuildInputs ++ [ super.gperf ]; }));
  gmp = dds (super.gmp);
  ocamlPackages = super.ocamlPackages.overrideScope' (self: super: {
    ligo-out = super.ligo-out.overrideAttrs (_: {
      patches = [ ./static.patch ];
    });
  });
}