import { ConfigService } from "./services/configService";
import { SafeService } from "./services/safeService";
import { Web3Service } from "./services/web3Service";

export const configService = new ConfigService();
export const safeService = new SafeService();
export const web3Service = new Web3Service();