"use strict";

const fetch = require("node-fetch"),
      fs = require("fs"),
      parser = require("docker-file-parser");

(async() => {
  const dockerfile = fs.readFileSync("./tmp/kdeneon/Dockerfile", { encoding: "utf8" }),
        commands = parser.parse(dockerfile, { includeComments: false });

  const scripts = [],
        files = [];
  let envvars = {};

  for (const command of commands) {
    if (
      command.name === "FROM" ||
      command.name === "MAINTAINER" ||
      command.name === "WORKDIR" ||
      command.name === "CMD"
    ) {
      continue;
    } else if (command.name === "USER") {
      console.info("INFO: USER is skipped since user name is always 'vagrant' on Vagrant");
      continue;
    } else if (command.name === "RUN") {
console.log(command)
      scripts.push(command.args)
    } else if (command.name === "ADD") {
      // TODO support URL in src
      // TODO unarchive src if they are archive (e.g. tar.gz)
      files.push({
        src: command.args[0],
        dest: command.args[1],
      });
    } else if (command.name === "COPY") {
      files.push({
        src: command.args[0],
        dest: command.args[1],
      });
    } else if (command.name === "ENV") {
      envvars = Object.assign(envvars, command.args);
    } else {
      throw new Error(`Command ${command.name} is not supported yet: ${JSON.stringify(command, null, 2)}`);
    }
  }
console.log(scripts)
  fs.writeFileSync("./tmp/kdeneon/Vagrantfile", `
    Vagrant.configure("2") do |config|
      config.vm.box = "ubuntu/bionic64"

      ${files.map((file) => {
        return `config.vm.provision "file", source: "${file.src}", destination: "${file.dest}"`
      }).join("\n")}

      config.vm.provision "shell",
        env: {
          ${Object.entries(envvars).map((envvar) => {
            return `"${envvar[0]}" => "${envvar[1]}"`
          }).join(",\n")}
        },
        inline: "${scripts.join(" && ").replace(/\"/g, "\\\"")}"
    end
  `, { encoding: "utf8" });
})();
